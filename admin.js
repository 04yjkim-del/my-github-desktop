const AI_RANDOM_SAMPLE_RATE = 0.03;

const API_BASE = (() => {
  const host = window.location.hostname;
  if (host === "localhost" || host === "127.0.0.1") return "http://localhost:3000";
  return window.location.origin.replace(/:\d+$/, ":3000");
})();

const ADMIN_TOKEN_KEY = "showupAdminToken";
let adminToken = sessionStorage.getItem(ADMIN_TOKEN_KEY) || "";
let livePayouts = [];
let liveVideos = [];
let liveReports = [];
let liveComments = [];
let liveCandidates = [];
let liveUsers = [];
let liveRestrictedUsers = [];
let liveChallenge = null;
let livePredictions = [];
let predictionSummary = null;
let dashboardSummary = null;
let currentAdmin = null;
let adminPasswordChangeRequired = false;
const excludedVoteUserIds = new Set();
const removedCandidateUserIds = new Set();

const adminRoleLabels = {
  super: "최고 관리자",
  ops: "운영 관리자",
  review: "검수 관리자",
  finance: "정산 관리자"
};

const reportActionMap = {
  "문제 없음": "dismiss",
  "영상 숨김": "hide_video",
  "영상 삭제": "delete_video",
  "댓글 삭제": "delete_comment",
  "사용자 경고": "warn_user",
  "계정 일시정지": "suspend_user",
  "계정 영구정지": "ban_user",
  "추가 검토": "review_more"
};

const commentActionMap = {
  "댓글 삭제": "delete",
  "댓글 숨김": "hide",
  "공개 유지": "keep"
};

const userStatusLabels = {
  active: "정상",
  suspended: "일시정지",
  banned: "영구정지",
  withdraw_pending: "탈퇴 요청"
};

const reportStatusLabels = {
  open: "접수",
  reviewing: "추가 검토",
  resolved: "처리 완료",
  dismissed: "문제 없음"
};

const payoutStatusLabels = {
  pending_claim: "신청 대기",
  claimed: "신청 완료",
  reviewing: "검토 중",
  on_hold: "보류",
  approved: "지급 승인",
  paid: "지급 완료",
  expired: "만료"
};

const predictionStatusLabels = {
  locked: "확정 대기",
  correct: "정답",
  incorrect: "오답",
  winner: "당첨"
};

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function formatUsd(value) {
  return `$${Number(value || 0).toLocaleString("en-US")}`;
}

function formatDateTime(value) {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleString("en-US", { timeZone: "America/New_York", hour12: true });
}

function formatPhone(value) {
  const digits = String(value || "").replace(/\D/g, "");
  if (digits.length === 11) return `${digits.slice(0, 3)}-${digits.slice(3, 7)}-${digits.slice(7)}`;
  if (digits.length === 10) return `${digits.slice(0, 3)}-${digits.slice(3, 6)}-${digits.slice(6)}`;
  return value || "-";
}

async function adminApiRequest(path, options = {}) {
  const headers = {
    "Content-Type": "application/json",
    ...(options.headers || {})
  };
  if (adminToken) headers.Authorization = `Bearer ${adminToken}`;
  const response = await fetch(`${API_BASE}${path}`, { ...options, headers });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const err = new Error(data?.error?.message || "요청에 실패했습니다");
    err.code = data?.error?.code || "";
    err.status = response.status;
    throw err;
  }
  return data;
}

async function loadLivePayouts() {
  const badge = document.querySelector("#payoutReviewCount");
  if (badge) badge.textContent = "불러오는 중";
  try {
    const data = await adminApiRequest("/api/admin/payouts");
    livePayouts = data.items || [];
    const reviewing = livePayouts.filter((item) =>
      ["claimed", "reviewing", "on_hold"].includes(item.status)
    ).length;
    if (badge) badge.textContent = `${reviewing}건 검토`;
    renderPayouts();
    updateDashboardCounts();
  } catch (err) {
    livePayouts = [];
    if (badge) badge.textContent = "연결 실패";
    renderPayouts(err.message || "상금 목록을 불러오지 못했습니다");
  }
}

function updateDashboardCounts() {
  const summary = dashboardSummary || {};
  const setText = (id, value, suffix) => {
    const el = document.querySelector(id);
    if (el) el.textContent = `${value ?? 0}${suffix}`;
  };
  setText("#dashVideosPending", summary.videosPending, "개");
  setText("#dashReportsOpen", summary.reportsOpen, "개");
  setText("#dashCommentsFlagged", summary.commentsFlagged, "건");
  setText("#dashVoteConfirmPending", summary.voteConfirmPending, "개");
  setText("#dashPayoutsReviewing", summary.payoutsReviewing ?? livePayouts.filter((item) =>
    ["claimed", "reviewing", "on_hold"].includes(item.status)
  ).length, "건");

  const videoBadge = document.querySelector("#videoPendingBadge");
  if (videoBadge) videoBadge.textContent = `AI 검토 필요 ${summary.videosPending ?? liveVideos.length}개`;

  const reportBadge = document.querySelector("#reportOpenBadge");
  if (reportBadge) {
    const openCount = liveReports.filter((item) => item.status === "open").length;
    const reviewingCount = liveReports.filter((item) => item.status === "reviewing").length;
    if (liveReports.length && (openCount || reviewingCount)) {
      reportBadge.textContent = reviewingCount
        ? `접수 ${openCount} · 추가검토 ${reviewingCount}`
        : `${openCount}개 접수`;
    } else {
      reportBadge.textContent = `${summary.reportsOpen ?? 0}개 접수`;
    }
  }
}

async function loadDashboardSummary() {
  try {
    dashboardSummary = await adminApiRequest("/api/admin/dashboard/summary");
    updateDashboardCounts();
  } catch {
    dashboardSummary = null;
  }
}

async function loadLiveVideos() {
  const table = document.querySelector("#videoTable");
  if (table) table.innerHTML = `<div class="payout-empty">불러오는 중...</div>`;
  try {
    const data = await adminApiRequest("/api/admin/videos?status=ai_review");
    liveVideos = data.items || [];
    updateDashboardCounts();
    renderVideos();
  } catch (err) {
    liveVideos = [];
    if (table) {
      table.innerHTML = `<div class="payout-empty">${escapeHtml(err.message || "영상 목록을 불러오지 못했습니다")}</div>`;
    }
  }
}

async function loadLiveReports() {
  const table = document.querySelector("#reportTable");
  if (table) table.innerHTML = `<div class="payout-empty">불러오는 중...</div>`;
  try {
    const [openData, reviewingData] = await Promise.all([
      adminApiRequest("/api/admin/reports?status=open"),
      adminApiRequest("/api/admin/reports?status=reviewing")
    ]);
    liveReports = [...(openData.items || []), ...(reviewingData.items || [])].sort(
      (a, b) => new Date(b.createdAt) - new Date(a.createdAt)
    );
    updateDashboardCounts();
    renderReports();
  } catch (err) {
    liveReports = [];
    if (table) {
      table.innerHTML = `<div class="payout-empty">${escapeHtml(err.message || "신고 목록을 불러오지 못했습니다")}</div>`;
    }
  }
}

async function loadLiveComments() {
  const table = document.querySelector("#commentTable");
  if (table) table.innerHTML = `<div class="payout-empty">불러오는 중...</div>`;
  try {
    const data = await adminApiRequest("/api/admin/comments?flagged=1");
    liveComments = data.items || [];
    updateDashboardCounts();
    renderComments();
  } catch (err) {
    liveComments = [];
    if (table) {
      table.innerHTML = `<div class="payout-empty">${escapeHtml(err.message || "댓글 목록을 불러오지 못했습니다")}</div>`;
    }
  }
}

async function loadLiveVote() {
  try {
    const [challengeData, candidatesData] = await Promise.all([
      adminApiRequest("/api/admin/challenges/current"),
      adminApiRequest("/api/admin/challenges/current/candidates?limit=20")
    ]);
    liveChallenge = challengeData.challenge || null;
    liveCandidates = candidatesData.items || [];
    renderVote();
    updateDashboardCounts();
  } catch (err) {
    liveChallenge = null;
    liveCandidates = [];
    const list = document.querySelector("#candidateList");
    if (list) {
      list.innerHTML = `<div class="payout-empty">${escapeHtml(err.message || "투표 정보를 불러오지 못했습니다")}</div>`;
    }
  }
}

async function loadLivePredictions() {
  const badge = document.querySelector("#predictionSummaryBadge");
  const note = document.querySelector("#predictionActionNote");
  const table = document.querySelector("#predictionTable");
  if (badge) badge.textContent = "불러오는 중";
  if (table) table.innerHTML = `<div class="payout-empty">불러오는 중...</div>`;
  try {
    const data = await adminApiRequest("/api/admin/predictions");
    livePredictions = data.items || [];
    predictionSummary = data.summary || null;
    updatePredictionActionUi(note);
    renderPredictions();
  } catch (err) {
    livePredictions = [];
    predictionSummary = null;
    if (badge) badge.textContent = "연결 실패";
    updatePredictionActionUi(note);
    renderPredictions(err.message || "예측 목록을 불러오지 못했습니다");
  }
}

function updatePredictionActionUi(noteEl) {
  const badge = document.querySelector("#predictionSummaryBadge");
  const evaluateBtn = document.querySelector("#predictionEvaluateButton");
  const drawBtn = document.querySelector("#predictionDrawButton");
  const summary = predictionSummary || { total: 0, locked: 0, correct: 0, incorrect: 0, winner: 0 };

  if (badge) {
    if (!adminToken) badge.textContent = "로그인 필요";
    else if (!summary.total) badge.textContent = "참여 0건";
    else {
      badge.textContent = `참여 ${summary.total} · 대기 ${summary.locked} · 정답 ${summary.correct} · 당첨 ${summary.winner}`;
    }
  }

  const canEvaluate = Boolean(adminToken && summary.locked > 0);
  const canDraw = Boolean(adminToken && summary.correct > 0 && summary.winner < summary.correct);
  if (evaluateBtn) evaluateBtn.disabled = !canEvaluate;
  if (drawBtn) drawBtn.disabled = !canDraw;

  if (noteEl) {
    if (!adminToken) noteEl.textContent = "관리자 로그인 후 BET 예측을 관리할 수 있습니다.";
    else if (summary.locked > 0) {
      noteEl.textContent = `판정 대기 ${summary.locked}건 · 투표 관리에서 최종 우승자 확정 후 「정답 판정」을 누르세요.`;
    } else if (summary.correct > summary.winner) {
      noteEl.textContent = `정답 ${summary.correct}명 · 아직 추첨 전 ${summary.correct - summary.winner}명 · 「당첨자 추첨」으로 최대 5명을 뽑습니다.`;
    } else if (summary.total) {
      noteEl.textContent = "이번 주 BET 처리가 완료되었거나, 아직 참여자가 없습니다.";
    } else {
      noteEl.textContent = "아직 BET 참여자가 없습니다. 사용자 앱 BET 탭에서 확정하면 여기에 표시됩니다.";
    }
  }
}

async function handlePredictionEvaluate() {
  if (!confirm("현재 챌린지 BET 예측을 최종 1·2·3등과 비교해 정답/오답으로 판정합니다. 계속할까요?")) return;
  try {
    const data = await adminApiRequest("/api/admin/predictions/evaluate", { method: "POST" });
    const summary = data.summary || {};
    showToast(`정답 판정 완료 · 정답 ${summary.correct ?? 0} · 오답 ${summary.incorrect ?? 0}`);
    await loadLivePredictions();
  } catch (err) {
    showToast(err.message || "정답 판정에 실패했습니다");
  }
}

async function handlePredictionDraw() {
  const input = window.prompt("추첨할 당첨자 수 (1~20, 기본 5)", "5");
  if (input === null) return;
  const winnerCount = Number.parseInt(input, 10) || 5;
  if (!confirm(`정답자 중 ${winnerCount}명을 무작위로 추첨합니다. 계속할까요?`)) return;
  try {
    const data = await adminApiRequest("/api/admin/predictions/draw", {
      method: "POST",
      body: JSON.stringify({ winnerCount })
    });
    showToast(`당첨자 ${data.winnerCount ?? 0}명 추첨 완료`);
    await loadLivePredictions();
  } catch (err) {
    showToast(err.message || "당첨자 추첨에 실패했습니다");
  }
}

function formatPredictionPick(pick) {
  if (!pick) return "-";
  return pick.handle || pick.label || pick.userId || "-";
}

function renderPredictions(errorMessage = "") {
  const table = document.querySelector("#predictionTable");
  if (!table) return;

  if (errorMessage) {
    table.innerHTML = `<div class="payout-empty">${escapeHtml(errorMessage)}<br />API 서버(localhost:3000)가 켜져 있는지 확인하세요.</div>`;
    return;
  }

  if (!adminToken) {
    table.innerHTML = `<div class="payout-empty">관리자 로그인 후 BET 예측 목록을 불러옵니다.</div>`;
    return;
  }

  if (!livePredictions.length) {
    table.innerHTML = `<div class="payout-empty">표시할 BET 예측이 없습니다. 사용자 앱에서 BET 확정 후 다시 확인하세요.</div>`;
    return;
  }

  table.innerHTML = livePredictions.map((item) => {
    const statusLabel = predictionStatusLabels[item.status] || item.status;
    const picks = item.picks || {};
    return `
      <article class="table-row prediction-row">
        <div>
          <strong>${escapeHtml(item.handle || `@${item.username}`)}</strong>
          <small>${escapeHtml(item.name || "")} · 확정 ${escapeHtml(formatDateTime(item.lockedAt))}</small>
        </div>
        <span class="status ${predictionStatusClass(statusLabel)}">${escapeHtml(statusLabel)}</span>
        <div class="prediction-picks">
          <span>1위 ${escapeHtml(formatPredictionPick(picks.rank1))}</span>
          <span>2위 ${escapeHtml(formatPredictionPick(picks.rank2))}</span>
          <span>3위 ${escapeHtml(formatPredictionPick(picks.rank3))}</span>
        </div>
      </article>
    `;
  }).join("");
}

function predictionStatusClass(label) {
  if (/당첨|정답/.test(label)) return "live";
  if (/대기/.test(label)) return "warn";
  return "danger";
}

async function loadLiveUsers(query = "") {
  const table = document.querySelector("#userTable");
  if (table) table.innerHTML = `<div class="payout-empty">불러오는 중...</div>`;
  try {
    const q = query.trim();
    const path = q ? `/api/admin/users?q=${encodeURIComponent(q)}` : "/api/admin/users";
    const data = await adminApiRequest(path);
    liveUsers = data.items || [];
    renderUsers();
  } catch (err) {
    liveUsers = [];
    if (table) {
      table.innerHTML = `<div class="payout-empty">${escapeHtml(err.message || "회원 목록을 불러오지 못했습니다")}</div>`;
    }
  }
}

async function loadRestrictedUsers() {
  const table = document.querySelector("#restrictedUserTable");
  const countEl = document.querySelector("#restrictedUserCount");
  if (table) table.innerHTML = `<div class="payout-empty">불러오는 중...</div>`;
  try {
    const data = await adminApiRequest("/api/admin/users/restricted/list");
    liveRestrictedUsers = data.items || [];
    if (countEl) countEl.textContent = `${liveRestrictedUsers.length}명`;
    renderRestrictedUsers();
  } catch (err) {
    liveRestrictedUsers = [];
    if (countEl) countEl.textContent = "0명";
    if (table) {
      table.innerHTML = `<div class="payout-empty">${escapeHtml(err.message || "제한 계정 목록을 불러오지 못했습니다")}</div>`;
    }
  }
}

async function loadUserSections(query = "") {
  await Promise.all([loadRestrictedUsers(), loadLiveUsers(query)]);
}

async function loadAllAdminData() {
  if (!adminToken) return;
  await Promise.all([
    loadDashboardSummary(),
    loadLiveVideos(),
    loadLiveReports(),
    loadLiveComments(),
    loadLiveVote(),
    loadLivePredictions(),
    loadLivePayouts(),
    loadUserSections()
  ]);
}

function formatAiRisk(video) {
  const flags = video.aiFlags || {};
  const active = Object.entries(flags).filter(([, value]) => value).map(([key]) => key);
  if (active.length) return active.join(", ");
  if (video.aiScore != null) return `AI 점수 ${video.aiScore}`;
  if (video.rejectReason) return video.rejectReason;
  return "AI 검토";
}

function formatReportTarget(report) {
  const typeLabels = { video: "영상", comment: "댓글", user: "계정" };
  const label = typeLabels[report.targetType] || report.targetType;
  const reporter = report.reporter?.handle || report.reporter?.username ? `@${report.reporter.username}` : "";
  return `${label} · 신고자 ${reporter || "-"}`;
}

function formatCommentStatus(comment) {
  if (comment.reportCount > 0) return "신고 접수";
  if (comment.status === "hidden") return "숨김";
  return "공개";
}

async function handleVideoAction(videoId, action) {
  const video = liveVideos.find((item) => item.id === videoId);
  const label = video?.title || videoId;
  if (!confirm(`${label} · ${action} 처리하시겠습니까?`)) return;

  try {
    if (action === "관리자 승인") {
      await adminApiRequest(`/api/admin/videos/${videoId}/approve`, { method: "POST" });
      showToast(`${label}: 승인 · 공개`);
    } else if (action === "관리자 반려") {
      const reason = window.prompt("반려 사유", "챌린지 규정 위반");
      if (!reason) return;
      await adminApiRequest(`/api/admin/videos/${videoId}/reject`, {
        method: "POST",
        body: JSON.stringify({ reason })
      });
      showToast(`${label}: 반려 처리`);
    }
    await Promise.all([loadLiveVideos(), loadDashboardSummary()]);
  } catch (err) {
    showToast(err.message || "영상 처리에 실패했습니다");
  }
}

async function handleReportAction(reportId, actionLabel) {
  const report = liveReports.find((item) => item.id === reportId);
  const apiAction = reportActionMap[actionLabel];
  if (!apiAction) return;
  const label = formatReportTarget(report || { targetType: "?", reporter: {} });
  if (!confirm(`${label} · ${actionLabel} 처리하시겠습니까?`)) return;

  try {
    const body = { action: apiAction };
    if (apiAction === "suspend_user") {
      const until = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
      body.suspendedUntil = until;
    }
    await adminApiRequest(`/api/admin/reports/${reportId}/resolve`, {
      method: "POST",
      body: JSON.stringify(body)
    });
    showToast(`${label}: ${actionLabel} 처리`);
    await Promise.all([loadLiveReports(), loadDashboardSummary()]);
  } catch (err) {
    showToast(err.message || "신고 처리에 실패했습니다");
  }
}

async function handleCommentAction(commentId, actionLabel) {
  const comment = liveComments.find((item) => item.id === commentId);
  const apiAction = commentActionMap[actionLabel];
  if (!apiAction) return;
  const label = comment?.author?.handle || commentId;
  if (!confirm(`${label} 댓글 · ${actionLabel} 처리하시겠습니까?`)) return;

  try {
    await adminApiRequest(`/api/admin/comments/${commentId}/moderate`, {
      method: "POST",
      body: JSON.stringify({ action: apiAction })
    });
    showToast(`${label}: ${actionLabel} 처리`);
    await Promise.all([loadLiveComments(), loadDashboardSummary()]);
  } catch (err) {
    showToast(err.message || "댓글 처리에 실패했습니다");
  }
}

async function handleVoteStep(step) {
  if (step === "일반 투표 종료") {
    showToast("General voting closes automatically on the ET schedule");
    return;
  }
  if (step === "TOP10 후보 확인") {
    await loadLiveVote();
    showToast("후보 TOP20 갱신 완료");
    return;
  }
  if (step === "부정투표 의심 제거") {
    if (!confirm("동일 IP 중복 투표를 무효화하시겠습니까?")) return;
    try {
      const data = await adminApiRequest("/api/admin/challenges/current/votes/invalidate", {
        method: "POST",
        body: JSON.stringify({})
      });
      showToast(`부정투표 ${data.invalidated || 0}건 무효화`);
      await loadLiveVote();
    } catch (err) {
      showToast(err.message || "부정투표 제거에 실패했습니다");
    }
    return;
  }

  const stepMap = {
    "TOP10 확정": "top10",
    "TOP3 파이널 확정": "top3",
    "최종 우승자 확정": "winners"
  };
  const apiStep = stepMap[step];
  if (!apiStep) return;

  const excludeUserIds = [...excludedVoteUserIds];
  const excludedLabels = liveCandidates
    .filter((item) => excludedVoteUserIds.has(item.userId))
    .map((item) => item.handle || `@${item.username}`)
    .join(", ");
  const confirmMessage = excludeUserIds.length
    ? `${step} 실행\n\n제외 후보 (${excludeUserIds.length}명): ${excludedLabels}\n\n계속하시겠습니까?`
    : `${step}을(를) 실행하시겠습니까?`;
  if (!confirm(confirmMessage)) return;

  try {
    const body = { step: apiStep };
    if (excludeUserIds.length) body.excludeUserIds = excludeUserIds;

    await adminApiRequest("/api/admin/challenges/current/confirm", {
      method: "POST",
      body: JSON.stringify(body)
    });
    excludeUserIds.forEach((userId) => removedCandidateUserIds.add(userId));
    excludedVoteUserIds.clear();
    showToast(`${step} 완료${excludeUserIds.length ? ` · 제외 ${excludeUserIds.length}명` : ""}`);
    await Promise.all([loadLiveVote(), loadDashboardSummary(), loadLivePayouts()]);
  } catch (err) {
    showToast(err.message || "투표 확정에 실패했습니다");
  }
}

async function handleUserAction(userId, action) {
  const user = liveUsers.find((item) => item.id === userId)
    || liveRestrictedUsers.find((item) => item.id === userId);
  const label = user?.handle || userId;

  if (action === "detail") {
    try {
      const data = await adminApiRequest(`/api/admin/users/${userId}`);
      const stats = data.stats || {};
      const info = data.user || {};
      window.alert(
        [
          `아이디: ${info.handle || label}`,
          `이름: ${info.name || "-"}`,
          `상태: ${userStatusLabels[info.status] || info.status}`,
          `업로드 ${stats.uploadCount ?? 0} · 투표 ${stats.voteCount ?? 0} · 신고 ${stats.reportCount ?? 0}`,
          `가입: ${formatDateTime(info.createdAt)}`
        ].join("\n")
      );
    } catch (err) {
      showToast(err.message || "회원 정보를 불러오지 못했습니다");
    }
    return;
  }

  if (!confirm(`${label} · ${action} 처리하시겠습니까?`)) return;

  try {
    if (action === "suspend") {
      const until = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
      await adminApiRequest(`/api/admin/users/${userId}/suspend`, {
        method: "POST",
        body: JSON.stringify({ until })
      });
      showToast(`${label}: 일시정지`);
    } else if (action === "ban") {
      await adminApiRequest(`/api/admin/users/${userId}/ban`, { method: "POST", body: "{}" });
      showToast(`${label}: 영구정지`);
    } else if (action === "withdraw") {
      await adminApiRequest(`/api/admin/users/${userId}/withdraw`, { method: "POST", body: "{}" });
      showToast(`${label}: 탈퇴 처리`);
    }
    await loadUserSections(document.querySelector("#adminSearch")?.value || "");
  } catch (err) {
    showToast(err.message || "회원 처리에 실패했습니다");
  }
}

function reinstateLabel(status) {
  if (status === "suspended") return "정지 해제";
  if (status === "banned") return "영구정지 해제";
  if (status === "withdraw_pending") return "탈퇴 취소";
  return "제한 해제";
}

function formatRestrictedMeta(user) {
  if (user.status === "suspended" && user.suspendedUntil) {
    return `정지 만료 ${formatDateTime(user.suspendedUntil)}`;
  }
  if (user.status === "withdraw_pending" && user.withdrawRequestedAt) {
    return `탈퇴 요청 ${formatDateTime(user.withdrawRequestedAt)}`;
  }
  return `처리 시각 ${formatDateTime(user.createdAt)}`;
}

async function handleRestrictedUserAction(userId, action = "reinstate") {
  const user = liveRestrictedUsers.find((item) => item.id === userId);
  const label = user?.handle || userId;

  if (action === "confirm-withdraw") {
    if (!confirm(`${label} · 탈퇴를 최종 확인하시겠습니까?\n회원정보가 삭제되며 되돌릴 수 없습니다.`)) return;
    try {
      await adminApiRequest(`/api/admin/users/${userId}/withdraw/confirm`, {
        method: "POST",
        body: JSON.stringify({ reason: "admin confirm withdraw" })
      });
      showToast(`${label}: 완전 탈퇴 완료`);
      await loadUserSections(document.querySelector("#adminSearch")?.value || "");
    } catch (err) {
      showToast(err.message || "탈퇴 확인에 실패했습니다");
    }
    return;
  }

  const actionLabel = reinstateLabel(user?.status);
  if (!confirm(`${label} · ${actionLabel} 하시겠습니까?`)) return;

  try {
    await adminApiRequest(`/api/admin/users/${userId}/reinstate`, {
      method: "POST",
      body: JSON.stringify({ reason: "admin restore" })
    });
    showToast(`${label}: ${actionLabel} 완료`);
    await loadUserSections(document.querySelector("#adminSearch")?.value || "");
  } catch (err) {
    showToast(err.message || "제한 해제에 실패했습니다");
  }
}

function renderMinorReviewBox(review) {
  if (!review?.needsGuardian) {
    return `
      <article class="payout-review-box">
        <h4>수상자 구분</h4>
        <dl>
          <dt>대상</dt><dd>성인 수상자</dd>
          <dt>휴대폰 인증</dt><dd>${review?.member?.phoneVerified ? "완료" : "미완료"}</dd>
        </dl>
      </article>
    `;
  }

  return `
    <article class="payout-review-box">
      <h4>수상자 구분</h4>
      <dl>
        <dt>대상</dt><dd class="status warn">18세 미만</dd>
        <dt>보호자 동의</dt><dd class="${review?.guardianVerified ? "status ok" : "status warn"}">${review?.guardianVerified ? "완료" : "미완료"}</dd>
        <dt>휴대폰 인증</dt><dd>${review?.member?.phoneVerified ? "완료" : "미완료"}</dd>
        <dt>안내</dt><dd>미성년·보호자·계좌 명의를 수동 확인하세요.</dd>
      </dl>
    </article>
  `;
}

function renderHoldReasonsBox(review) {
  const reasons = review?.holdReasons || [];
  if (!reasons.length) {
    return `
      <div class="payout-compare is-ok">
        <strong>자동 검토</strong>
        <p>18세 미만 · 보호자 미동의 · 예금주 불일치 항목이 없습니다.</p>
      </div>
    `;
  }

  return `
    <div class="payout-compare is-hold">
      <strong>지급 보류 사유 (${reasons.length}건)</strong>
      <ul class="payout-hold-list">
        ${reasons.map((reason) => `<li><b>${escapeHtml(reason.label)}</b> · ${escapeHtml(reason.message)}</li>`).join("")}
      </ul>
    </div>
  `;
}

function renderPayoutReviewPanel(payout) {
  const review = payout.review || {};
  const member = review.member || {};
  const compare = review.accountReview || {};
  const compareClass = compare.level ? `is-${compare.level}` : "";

  return `
    <div class="payout-review-panel">
      <div class="payout-review-grid">
        <article class="payout-review-box">
          <h4>수상자</h4>
          <dl>
            <dt>이름</dt><dd>${escapeHtml(member.name || payout.user?.name || "-")}</dd>
            <dt>나이</dt><dd>${review.age != null ? `${review.age}세` : "-"}${review.needsGuardian ? " · 18세 미만" : ""}</dd>
            <dt>연락처</dt><dd>${escapeHtml(formatPhone(member.phone || payout.user?.phone))}</dd>
            <dt>휴대폰 인증</dt><dd>${member.phoneVerified ? "완료" : "미완료"}</dd>
          </dl>
        </article>
        ${renderMinorReviewBox(review)}
        <article class="payout-review-box">
          <h4>계좌 정보</h4>
          <dl>
            <dt>은행</dt><dd>${escapeHtml(payout.bankName || "-")}</dd>
            <dt>계좌번호</dt><dd>${escapeHtml(payout.bankAccount || "-")}</dd>
            <dt>예금주</dt><dd>${escapeHtml(payout.accountHolder || "-")}</dd>
          </dl>
        </article>
        <article class="payout-review-box">
          <h4>신청 상태</h4>
          <dl>
            <dt>상태</dt><dd>${escapeHtml(payoutStatusLabels[payout.status] || payout.status)}</dd>
            <dt>신청 시각</dt><dd>${escapeHtml(formatDateTime(payout.claimedAt))}</dd>
            <dt>챌린지</dt><dd>${escapeHtml(payout.weekKey || "-")}</dd>
          </dl>
        </article>
      </div>
      ${renderHoldReasonsBox(review)}
      <div class="payout-compare ${compareClass}">
        <strong>${escapeHtml(compare.label || "예금주 비교")}</strong>
        <p>${escapeHtml(compare.message || "비교 정보 없음")}</p>
      </div>
    </div>
  `;
}

function payoutActionButtons(payout) {
  const review = payout.review || {};
  const canReview = ["claimed", "reviewing", "on_hold"].includes(payout.status);
  const blocked = Boolean(review.blockApprove);
  const canApprove = canReview && payout.status !== "on_hold" && !blocked;
  const canHold = canReview && payout.status !== "on_hold";
  const canResume = payout.status === "on_hold";
  const canMarkPaid = payout.status === "approved";
  const id = payout.id;
  const approveHint = payout.status === "on_hold"
    ? "보류 해제(검토 재개) 후 승인"
    : blocked
      ? "보류 사유 해결 후 승인"
      : "";

  return `
    <div class="button-group">
      <button class="secondary" data-payout-action="notify" data-payout-id="${id}">알림 발송</button>
      ${canHold ? `<button class="danger" data-payout-action="hold" data-payout-id="${id}">보류</button>` : ""}
      ${canResume ? `<button class="secondary" data-payout-action="resume" data-payout-id="${id}">검토 재개</button>` : ""}
      ${canApprove ? `<button data-payout-action="approve" data-payout-id="${id}">지급 승인</button>` : `<button class="secondary" disabled title="${escapeHtml(approveHint)}">지급 승인</button>`}
      ${canMarkPaid ? `<button class="secondary" data-payout-action="paid" data-payout-id="${id}">지급 완료</button>` : ""}
      ${payout.status !== "paid" && payout.status !== "expired" ? `<button class="danger" data-payout-action="expire" data-payout-id="${id}">만료</button>` : ""}
    </div>
    ${approveHint ? `<p class="payout-meta-line">${escapeHtml(approveHint)}</p>` : ""}
  `;
}

async function handlePayoutAction(action, payoutId) {
  const payout = livePayouts.find((item) => item.id === payoutId);
  const label = payout ? `@${payout.user?.username || "회원"}` : payoutId;
  if (!confirm(`${label} · ${action} 처리하시겠습니까?`)) return;

  try {
    if (action === "notify") {
      await adminApiRequest(`/api/admin/payouts/${payoutId}/notify`, { method: "POST" });
      showToast(`${label}: 상금 수령 알림 발송`);
      return;
    }
    if (action === "hold") {
      const reason = window.prompt("보류 사유 (선택)", "예금주·수령 정보 불일치");
      await adminApiRequest(`/api/admin/payouts/${payoutId}/hold`, {
        method: "POST",
        body: JSON.stringify({ reason: reason || undefined })
      });
      showToast(`${label}: 보류 처리`);
      await loadLivePayouts();
      return;
    }
    if (action === "resume") {
      await adminApiRequest(`/api/admin/payouts/${payoutId}/resume-review`, { method: "POST" });
      showToast(`${label}: 검토 재개`);
      await loadLivePayouts();
      return;
    }
    if (action === "approve") {
      await adminApiRequest(`/api/admin/payouts/${payoutId}/approve`, { method: "POST" });
      showToast(`${label}: 지급 승인`);
      await loadLivePayouts();
      return;
    }
    if (action === "paid") {
      const transferRef = window.prompt("이체 참조번호", `TX-${Date.now()}`);
      if (!transferRef) return;
      await adminApiRequest(`/api/admin/payouts/${payoutId}/mark-paid`, {
        method: "POST",
        body: JSON.stringify({ transferRef })
      });
      showToast(`${label}: 지급 완료`);
      await loadLivePayouts();
      return;
    }
    if (action === "expire") {
      await adminApiRequest(`/api/admin/payouts/${payoutId}/expire`, { method: "POST" });
      showToast(`${label}: 만료 처리`);
      await loadLivePayouts();
    }
  } catch (err) {
    showToast(err.message || "처리에 실패했습니다");
  }
}

const sectionTitles = {
  dashboard: "오늘 처리해야 할 일",
  permissions: "관리자 권한",
  videos: "영상 검수",
  reports: "신고 처리",
  comments: "댓글 삭제",
  vote: "투표 관리",
  predictions: "BET 예측",
  payouts: "상금 지급",
  users: "회원 관리"
};

const videoActions = ["관리자 승인", "관리자 반려"];

const reportActions = [
  "문제 없음",
  "영상 숨김",
  "영상 삭제",
  "댓글 삭제",
  "사용자 경고",
  "계정 일시정지",
  "계정 영구정지",
  "추가 검토"
];

const commentActions = ["댓글 삭제", "댓글 숨김", "공개 유지"];

const voteSteps = [
  "일반 투표 종료",
  "TOP10 후보 확인",
  "부정투표 의심 제거",
  "TOP10 확정",
  "TOP3 파이널 확정",
  "최종 우승자 확정"
];

const payoutSteps = [
  "수령 신청 접수",
  "본인정보 확인",
  "계좌정보 확인",
  "부정참여 검토",
  "미성년자 보호자 동의 확인",
  "제세공과금 확인",
  "지급 승인",
  "지급 완료"
];

const transitionMessages = {
  "관리자 승인": "AI 검토 필요 → 공개",
  "관리자 반려": "AI 검토 필요 → 관리자 반려",
  "영상 숨김": "공개 → 숨김",
  "영상 삭제": "공개/숨김 → 삭제",
  "문제 없음": "신고 접수 → 문제 없음 / 대상 유지",
  "영상 삭제 신고": "신고 접수 → 영상 삭제 / 영상 공개 → 삭제",
  "댓글 삭제": "신고 접수 → 댓글 삭제 / 댓글 공개 → 삭제",
  "댓글 숨김": "댓글 공개 → 숨김 (작성자·본인만 보기)",
  "공개 유지": "검토 대기 → 공개 유지",
  "사용자 경고": "신고 접수 → 사용자 경고 / 정상 → 경고 1회",
  "계정 일시정지": "신고 접수 → 계정 일시정지 / 정상 → 일시정지",
  "계정 영구정지": "신고 접수 → 계정 영구정지 / 정상 → 영구정지",
  "추가 검토": "신고 접수 → 추가 검토",
  "일반 투표 시작": "대기 → 일반 투표 진행 중",
  "일반 투표 종료": "일반 투표 진행 중 → 일반 투표 종료",
  "TOP10 투표 시작": "TOP10 확정 → TOP10 투표 진행 중",
  "TOP10 투표 종료": "TOP10 투표 진행 중 → TOP10 투표 종료",
  "TOP3 파이널 시작": "TOP3 확정 → 파이널 투표 진행 중",
  "TOP3 파이널 종료": "파이널 투표 진행 중 → 파이널 투표 종료",
  "정지": "정상 → 일시정지",
  "영구정지": "정상 → 영구정지",
  "탈퇴 처리": "정상 → 탈퇴 요청 → 관리자 탈퇴 확인 → 삭제 완료"
};

const voteRuntime = {
  general: "closed",
  top10: "closed",
  final: "closed"
};

const voteAutoSchedule = [
  { key: "ready", label: "투표 대기", window: "일~금 18:00 이전", phase: "idle" },
  { key: "general", label: "일반 투표", window: "금 18:00 ~ 토 18:00", phase: "general_open" },
  { key: "top5", label: "TOP10 투표", window: "토 18:00 ~ 일 15:00", phase: "top10_open" },
  { key: "final", label: "TOP3 파이널", window: "일 15:00 ~ 일 18:00", phase: "final_open" },
  { key: "closed", label: "투표 종료", window: "일 18:00 이후", phase: "final_closed" }
];

const toast = document.querySelector("#adminToast");
document.body.classList.add("admin-locked");

function formatVoteCount(value) {
  return `${Number(value).toLocaleString("ko-KR")}표`;
}

function getKoreaNow() {
  const now = new Date();
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: "America/New_York",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  }).formatToParts(now);
  const pick = (type) => Number(parts.find((part) => part.type === type)?.value || 0);
  return new Date(pick("year"), pick("month") - 1, pick("day"), pick("hour"), pick("minute"), pick("second"));
}

function getVotePhaseFromSchedule() {
  const koreaTime = getKoreaNow();
  const day = koreaTime.getDay();
  const minutes = koreaTime.getHours() * 60 + koreaTime.getMinutes();

  if ((day === 5 && minutes >= 18 * 60) || (day === 6 && minutes < 18 * 60)) {
    return { key: "general", title: "일반 투표", text: "금 18:00 ~ 토 18:00 (자동)" };
  }
  if ((day === 6 && minutes >= 18 * 60) || (day === 0 && minutes < 15 * 60)) {
    return { key: "top5", title: "TOP10 투표", text: "토 18:00 ~ 일 15:00 (자동)" };
  }
  if (day === 0 && minutes >= 15 * 60 && minutes < 18 * 60) {
    return { key: "final", title: "TOP3 파이널", text: "일 15:00 ~ 일 18:00 (자동)" };
  }
  if (day === 0 && minutes >= 18 * 60) {
    return { key: "closed", title: "투표 종료", text: "일 18:00 이후 · 확정 대기" };
  }
  return { key: "ready", title: "투표 대기", text: "금 18:00에 일반 투표 자동 시작" };
}

function syncVoteRuntimeFromSchedule() {
  const phase = getVotePhaseFromSchedule();
  voteRuntime.general = "closed";
  voteRuntime.top10 = "closed";
  voteRuntime.final = "closed";

  if (phase.key === "general") {
    voteRuntime.general = "open";
  } else if (phase.key === "top5") {
    voteRuntime.general = "ended";
    voteRuntime.top10 = "open";
  } else if (phase.key === "final") {
    voteRuntime.general = "ended";
    voteRuntime.top10 = "ended";
    voteRuntime.final = "open";
  } else if (phase.key === "closed") {
    voteRuntime.general = "ended";
    voteRuntime.top10 = "ended";
    voteRuntime.final = "ended";
  }
  return phase;
}

function getVotePhaseLabel() {
  const phase = getVotePhaseFromSchedule();
  if (phase.key === "general") return "일반 투표 진행 중 (자동)";
  if (phase.key === "top5") return "TOP10 투표 진행 중 (자동)";
  if (phase.key === "final") return "TOP3 파이널 진행 중 (자동)";
  if (phase.key === "closed") return "투표 종료 · 확정 대기";
  return "투표 대기 (자동)";
}

function showToast(message) {
  toast.textContent = message;
  toast.classList.add("is-visible");
  clearTimeout(showToast.timer);
  showToast.timer = setTimeout(() => toast.classList.remove("is-visible"), 1800);
}

function statusClass(value) {
  if (/승인|정상|완료|전체 가능|지급 완료|불필요|공개/.test(value)) return "live";
  if (/대기|접수|검토|보류|의심|필요|미인증|신청 완료/.test(value)) return "warn";
  return "danger";
}

function actionButtons(actions, options = {}) {
  const { targetId, type, dangerPattern = /삭제|영구|반려|보류/ } = options;
  return actions.map((action) => {
    const className = dangerPattern.test(action) ? "danger" : action === "승인" || action === "문제 없음" ? "" : "secondary";
    const dataAttr = type && targetId
      ? ` data-${type}-action="${escapeHtml(action)}" data-${type}-id="${escapeHtml(targetId)}"`
      : "";
    return `<button class="${className}"${dataAttr}>${escapeHtml(action)}</button>`;
  }).join("");
}

function renderVideos() {
  const sampleRate = document.querySelector("#aiSampleRateNote");
  if (sampleRate) {
    sampleRate.textContent = `AI 통과 영상의 ${(AI_RANDOM_SAMPLE_RATE * 100).toFixed(0)}%가 랜덤 샘플로 관리자 검수 대기열에 들어갑니다.`;
  }
  const table = document.querySelector("#videoTable");
  if (!table) return;

  if (!adminToken) {
    table.innerHTML = `<div class="payout-empty">관리자 로그인 후 실제 영상 데이터를 불러옵니다.</div>`;
    return;
  }
  if (!liveVideos.length) {
    table.innerHTML = `<div class="payout-empty">검수 대기 영상이 없습니다.</div>`;
    return;
  }

  table.innerHTML = liveVideos.map((video) => {
    const handle = video.author?.handle || (video.author?.username ? `@${video.author.username}` : "@unknown");
    const statusLabel = "AI 검토 필요";
    return `
    <article class="table-row" data-video-id="${escapeHtml(video.id)}">
      <div>
        <strong>${escapeHtml(video.title)}</strong>
        <small>${escapeHtml(handle)}</small>
      </div>
      <span class="status ${statusClass(statusLabel)}">${escapeHtml(statusLabel)}</span>
      <div>
        <small>${escapeHtml(formatAiRisk(video))}</small>
        <div class="button-group">${actionButtons(videoActions, { targetId: video.id, type: "video" })}</div>
      </div>
    </article>
  `;
  }).join("");
}

function commentActionButtons(comment) {
  return commentActions.map((action) => {
    const className = /삭제/.test(action) ? "danger" : "secondary";
    return `<button class="${className}" data-comment-action="${escapeHtml(action)}" data-comment-id="${escapeHtml(comment.id)}">${escapeHtml(action)}</button>`;
  }).join("");
}

function renderComments() {
  const pending = liveComments.filter((item) => item.reportCount > 0).length;
  const countEl = document.querySelector("#commentPendingCount");
  if (countEl) countEl.textContent = `${pending}건 검토`;

  const table = document.querySelector("#commentTable");
  if (!table) return;

  if (!adminToken) {
    table.innerHTML = `<div class="payout-empty">관리자 로그인 후 실제 댓글 데이터를 불러옵니다.</div>`;
    return;
  }
  if (!liveComments.length) {
    table.innerHTML = `<div class="payout-empty">검토할 댓글이 없습니다.</div>`;
    return;
  }

  table.innerHTML = liveComments.map((comment) => {
    const statusLabel = formatCommentStatus(comment);
    return `
    <article class="table-row comment-row" data-comment-id="${escapeHtml(comment.id)}">
      <div>
        <strong>${escapeHtml(comment.author?.handle || "@unknown")}</strong>
        <small>${escapeHtml(comment.videoTitle || "영상")}</small>
        <p class="comment-body">${escapeHtml(comment.body)}</p>
        ${comment.reportCount > 0
          ? `<small class="comment-meta">신고 ${comment.reportCount}건</small>`
          : `<small class="comment-meta">신고 없음</small>`}
      </div>
      <span class="status ${statusClass(statusLabel)}">${escapeHtml(statusLabel)}</span>
      <div class="button-group">${commentActionButtons(comment)}</div>
    </article>
  `;
  }).join("");
}

function renderReports() {
  const table = document.querySelector("#reportTable");
  if (!table) return;

  if (!adminToken) {
    table.innerHTML = `<div class="payout-empty">관리자 로그인 후 실제 신고 데이터를 불러옵니다.</div>`;
    return;
  }
  if (!liveReports.length) {
    table.innerHTML = `<div class="payout-empty">접수된 신고가 없습니다.</div>`;
    return;
  }

  table.innerHTML = liveReports.map((report) => {
    const statusLabel = reportStatusLabels[report.status] || report.status;
    return `
    <article class="table-row" data-report-id="${escapeHtml(report.id)}">
      <div>
        <strong>${escapeHtml(formatReportTarget(report))}</strong>
        <small>${escapeHtml(report.reasonLabel || report.reasonCode || "")}</small>
      </div>
      <span class="status ${statusClass(statusLabel)}">${escapeHtml(statusLabel)}</span>
      <div class="button-group">${actionButtons(reportActions, { targetId: report.id, type: "report", dangerPattern: /삭제|영구|반려|보류/ })}</div>
    </article>
  `;
  }).join("");
}

function renderVoteAutoSchedule() {
  const phase = syncVoteRuntimeFromSchedule();
  const list = document.querySelector("#voteAutoScheduleList");
  if (list) {
    list.innerHTML = voteAutoSchedule.map((row) => `
      <li class="${row.key === phase.key ? "is-active" : ""}">
        <strong>${row.label}</strong>
        <span>${row.window}</span>
      </li>
    `).join("");
  }
  const clock = document.querySelector("#voteAutoClock");
  if (clock) {
    const now = getKoreaNow();
    const stamp = `${now.toLocaleString("en-US", { timeZone: "America/New_York", hour12: false })} ET`;
    clock.textContent = `기준 시각 ${stamp}`;
  }
}

function updateVotePhaseUi() {
  const phase = liveChallenge || syncVoteRuntimeFromSchedule();
  const label = liveChallenge?.title
    ? `${liveChallenge.title} (서버)`
    : getVotePhaseLabel();
  const badge = document.querySelector("#voteStatusBadge");
  const line = document.querySelector("#votePhaseStatus");
  if (badge) {
    badge.textContent = label;
    badge.className = `status ${/진행|투표/.test(label) ? "live" : /종료|대기|확정/.test(label) ? "warn" : ""}`;
  }
  if (line) {
    const detail = liveChallenge?.text || getVotePhaseFromSchedule().text;
    line.textContent = `현재 단계: ${liveChallenge?.title || getVotePhaseFromSchedule().title} · ${detail} · 후보 ${liveCandidates.length}명`;
  }
  renderVoteAutoSchedule();
}

function renderCandidateRow(candidate, { showExcludeControl = true } = {}) {
  const remaining = liveCandidates.filter(
    (item) => !excludedVoteUserIds.has(item.userId) && !removedCandidateUserIds.has(item.userId)
  );
  const effectiveRank = remaining.findIndex((item) => item.userId === candidate.userId) + 1;
  const inEffectiveTop10 = effectiveRank > 0 && effectiveRank <= 10;
  const isExcluded = excludedVoteUserIds.has(candidate.userId);

  return `
    <article class="candidate-row ${candidate.rank <= 10 ? "is-top10" : ""} ${inEffectiveTop10 ? "is-effective-top10" : ""} ${isExcluded ? "is-excluded" : ""}" data-candidate-rank="${candidate.rank}" data-candidate-user-id="${escapeHtml(candidate.userId)}">
      ${showExcludeControl ? `
      <label class="candidate-exclude">
        <input type="checkbox" data-candidate-exclude="${escapeHtml(candidate.userId)}" ${isExcluded ? "checked" : ""} aria-label="${escapeHtml(candidate.handle || candidate.username)} 제외" />
        <span>제외</span>
      </label>` : ""}
      <div class="candidate-row-main">
        <strong>${candidate.rank}위 ${escapeHtml(candidate.handle || `@${candidate.username}`)}</strong>
        <small>${escapeHtml(candidate.name || "")}${inEffectiveTop10 ? ` · 예상 TOP${effectiveRank}` : ""}</small>
      </div>
      <span>${formatVoteCount(candidate.votes)}</span>
    </article>
  `;
}

function renderCandidateExclusionSummary() {
  const badge = document.querySelector("#candidateExcludeBadge");
  const preview = document.querySelector("#candidateExcludePreview");
  const pendingCount = excludedVoteUserIds.size;
  const removedCount = removedCandidateUserIds.size;
  const activeCount = liveCandidates.filter(
    (item) => !excludedVoteUserIds.has(item.userId) && !removedCandidateUserIds.has(item.userId)
  ).length;

  if (badge) {
    if (pendingCount) badge.textContent = `제외 ${pendingCount}명`;
    else if (removedCount) badge.textContent = `확정 제외 ${removedCount}명`;
    else badge.textContent = "제외 없음";
    badge.className = `status ${pendingCount || removedCount ? "danger" : "warn"}`;
  }

  const countBadge = document.querySelector("#candidateCountBadge");
  if (countBadge && liveCandidates.length) {
    countBadge.textContent = removedCount || pendingCount ? `${activeCount}명 · 전체 ${liveCandidates.length}명` : `${liveCandidates.length}명`;
  }

  if (!preview) return;
  if (!pendingCount || !liveCandidates.length) {
    preview.hidden = true;
    preview.textContent = "";
    return;
  }

  const remaining = liveCandidates.filter(
    (item) => !excludedVoteUserIds.has(item.userId) && !removedCandidateUserIds.has(item.userId)
  );
  const top10Preview = remaining
    .slice(0, 10)
    .map((item, index) => `${index + 1}위 ${item.handle || `@${item.username}`}`)
    .join(" · ");
  preview.hidden = false;
  preview.textContent = `확정 시 TOP10 예상 (${remaining.length}명 중): ${top10Preview || "후보 부족"}`;
}

function renderVote() {
  const stepsEl = document.querySelector("#voteSteps");
  if (stepsEl) {
    stepsEl.innerHTML = voteSteps.map((step, index) => `
      <article>
        <span class="step-number">${index + 1}</span>
        <strong>${escapeHtml(step)}</strong>
        <button type="button" data-vote-step="${escapeHtml(step)}" ${adminToken ? "" : "disabled"}>처리</button>
      </article>
    `).join("");
  }

  const list = document.querySelector("#candidateList");
  if (!list) return;

  if (!adminToken) {
    list.innerHTML = `<div class="payout-empty">관리자 로그인 후 후보 목록을 불러옵니다.</div>`;
    updateVotePhaseUi();
    return;
  }
  if (!liveCandidates.length) {
    list.innerHTML = `<div class="payout-empty">표시할 후보가 없습니다.</div>`;
    updateVotePhaseUi();
    return;
  }

  const activeCandidates = liveCandidates.filter(
    (item) => !excludedVoteUserIds.has(item.userId) && !removedCandidateUserIds.has(item.userId)
  );
  const pendingExcluded = liveCandidates.filter((item) => excludedVoteUserIds.has(item.userId));

  if (!activeCandidates.length) {
    list.innerHTML = `<div class="payout-empty">표시할 후보가 없습니다. 제외를 해제하거나 목록을 갱신하세요.</div>`;
  } else {
    list.innerHTML = activeCandidates.map((candidate) => renderCandidateRow(candidate)).join("");
  }

  const excludedPanel = document.querySelector("#candidateExcludedPanel");
  const excludedList = document.querySelector("#candidateExcludedList");
  if (excludedPanel && excludedList) {
    if (!pendingExcluded.length) {
      excludedPanel.hidden = true;
      excludedList.innerHTML = "";
    } else {
      excludedPanel.hidden = false;
      excludedList.innerHTML = pendingExcluded.map((candidate) => renderCandidateRow(candidate)).join("");
    }
  }

  renderCandidateExclusionSummary();
  updateVotePhaseUi();
}

function renderPayouts(errorMessage = "") {
  const table = document.querySelector("#payoutTable");
  if (!table) return;

  if (errorMessage) {
    table.innerHTML = `<div class="payout-empty">${escapeHtml(errorMessage)}<br />API 서버(localhost:3000)가 켜져 있는지 확인하세요.</div>`;
    return;
  }

  if (!adminToken) {
    table.innerHTML = `<div class="payout-empty">관리자 로그인 후 실제 상금 데이터를 불러옵니다.</div>`;
    return;
  }

  if (!livePayouts.length) {
    table.innerHTML = `<div class="payout-empty">표시할 상금 내역이 없습니다. demo_user3 등으로 수령 신청 후 다시 확인하세요.</div>`;
    return;
  }

  table.innerHTML = livePayouts.map((payout) => {
    const handle = payout.user?.username ? `@${payout.user.username}` : "@unknown";
    const prize = `#${payout.rank} ${formatUsd(payout.amountKrw)}`;
    const statusLabel = payoutStatusLabels[payout.status] || payout.status;
    return `
      <article class="table-row payout-review-row" data-payout-id="${payout.id}">
        <div>
          <strong>${escapeHtml(handle)}</strong>
          <small>${escapeHtml(payout.user?.name || "")} · ${escapeHtml(prize)}</small>
        </div>
        <span class="status ${statusClass(statusLabel)}">${escapeHtml(statusLabel)}</span>
        <div class="payout-card">
          ${renderPayoutReviewPanel(payout)}
          <div class="payout-steps">
            ${payoutSteps.map((step, index) => `<span class="${index <= payout.reviewStep ? "is-done" : ""}">${step}</span>`).join("")}
          </div>
          ${payoutActionButtons(payout)}
        </div>
      </article>
    `;
  }).join("");
}

function renderRestrictedUsers() {
  const table = document.querySelector("#restrictedUserTable");
  const countEl = document.querySelector("#restrictedUserCount");
  if (!table) return;

  if (!adminToken) {
    table.innerHTML = `<div class="payout-empty">관리자 로그인 후 제한 계정 목록을 불러옵니다.</div>`;
    if (countEl) countEl.textContent = "0명";
    return;
  }
  if (!liveRestrictedUsers.length) {
    table.innerHTML = `<div class="payout-empty">현재 정지·영구정지·탈퇴 요청 계정이 없습니다.</div>`;
    if (countEl) countEl.textContent = "0명";
    return;
  }

  if (countEl) countEl.textContent = `${liveRestrictedUsers.length}명`;

  table.innerHTML = liveRestrictedUsers.map((user) => {
    const statusLabel = userStatusLabels[user.status] || user.status;
    const restoreLabel = reinstateLabel(user.status);
    const withdrawConfirmButton =
      user.status === "withdraw_pending"
        ? `<button class="danger" data-restricted-action="confirm-withdraw" data-user-id="${escapeHtml(user.id)}">탈퇴 확인</button>`
        : "";
    return `
    <article class="table-row" data-restricted-user-id="${escapeHtml(user.id)}">
      <div>
        <strong>${escapeHtml(user.handle || `@${user.username}`)}</strong>
        <small>${escapeHtml(user.name || "")} · ${escapeHtml(formatRestrictedMeta(user))}</small>
      </div>
      <span class="status ${statusClass(statusLabel)}">${escapeHtml(statusLabel)}</span>
      <div>
        <small>업로드 ${user.uploadCount ?? 0} · 투표 ${user.voteCount ?? 0} · 신고 ${user.reportCount ?? 0}</small>
        <div class="button-group">
          <button class="restore-button" data-restricted-action="reinstate" data-user-id="${escapeHtml(user.id)}">${escapeHtml(restoreLabel)}</button>
          ${withdrawConfirmButton}
          <button class="secondary" data-user-action="detail" data-user-id="${escapeHtml(user.id)}">상세</button>
        </div>
      </div>
    </article>
  `;
  }).join("");
}

function renderUsers() {
  const table = document.querySelector("#userTable");
  if (!table) return;

  if (!adminToken) {
    table.innerHTML = `<div class="payout-empty">관리자 로그인 후 회원 목록을 불러옵니다.</div>`;
    return;
  }
  if (!liveUsers.length) {
    table.innerHTML = `<div class="payout-empty">표시할 회원이 없습니다.</div>`;
    return;
  }

  table.innerHTML = liveUsers.map((user) => {
    const joined = user.createdAt ? new Date(user.createdAt).toLocaleDateString("ko-KR") : "-";
    const ageNote = user.ageGroup || "-";
    const statusLabel = userStatusLabels[user.status] || user.status;
    return `
    <article class="table-row" data-user-id="${escapeHtml(user.id)}">
      <div>
        <strong>${escapeHtml(user.handle || `@${user.username}`)}</strong>
        <small>가입일 ${escapeHtml(joined)} · ${escapeHtml(ageNote)}</small>
      </div>
      <span class="status ${statusClass(statusLabel)}">${escapeHtml(statusLabel)}</span>
      <div>
        <small>
          업로드 ${user.uploadCount ?? 0} · 투표 ${user.voteCount ?? 0} · 신고 ${user.reportCount ?? 0}
        </small>
        <div class="button-group">
          <button class="secondary" data-user-action="detail" data-user-id="${escapeHtml(user.id)}">상세</button>
          <button class="secondary" data-user-action="suspend" data-user-id="${escapeHtml(user.id)}">정지</button>
          <button class="danger" data-user-action="ban" data-user-id="${escapeHtml(user.id)}">영구정지</button>
          <button class="secondary" data-user-action="withdraw" data-user-id="${escapeHtml(user.id)}">탈퇴 처리</button>
        </div>
      </div>
    </article>
  `;
  }).join("");
}

function renderAdmin() {
  renderVideos();
  renderReports();
  renderComments();
  renderVote();
  renderPredictions();
  renderPayouts();
  renderRestrictedUsers();
  renderUsers();
  if (adminToken) updateDashboardCounts();
}

const sectionLoaders = {
  dashboard: loadDashboardSummary,
  videos: loadLiveVideos,
  reports: loadLiveReports,
  comments: loadLiveComments,
  vote: loadLiveVote,
  predictions: loadLivePredictions,
  payouts: loadLivePayouts,
  users: () => loadUserSections(document.querySelector("#adminSearch")?.value || "")
};

function openSection(sectionId) {
  document.querySelectorAll(".side-nav button").forEach((button) => {
    button.classList.toggle("is-active", button.dataset.adminSection === sectionId);
  });
  document.querySelectorAll(".admin-section").forEach((section) => {
    section.classList.toggle("is-visible", section.id === sectionId);
  });
  document.querySelector("#adminTitle").textContent = sectionTitles[sectionId] || "관리자";
  if (adminToken && sectionLoaders[sectionId]) {
    const loader = sectionLoaders[sectionId];
    if (sectionId === "users") {
      loader(document.querySelector("#adminSearch")?.value || "");
    } else {
      loader();
    }
  }
}

function filterRows(query) {
  const normalized = query.trim().toLowerCase();
  document.querySelectorAll(".table-row, .candidate-row").forEach((row) => {
    row.hidden = normalized && !row.textContent.toLowerCase().includes(normalized);
  });
}

function bindEvents() {
  document.querySelector("#adminLoginButton").addEventListener("click", handleAdminLogin);
  document.querySelector("#adminPassword").addEventListener("keydown", (event) => {
    if (event.key === "Enter") handleAdminLogin();
  });
  document.querySelector("#adminNumber").addEventListener("keydown", (event) => {
    if (event.key === "Enter") handleAdminLogin();
  });

  document.querySelector("#adminLogoutButton")?.addEventListener("click", handleAdminLogout);
  document.querySelector("#adminPasswordForm")?.addEventListener("submit", handleAdminChangePassword);

  document.addEventListener("change", (event) => {
    const excludeInput = event.target.closest("[data-candidate-exclude]");
    if (excludeInput) {
      const userId = excludeInput.dataset.candidateExclude;
      if (excludeInput.checked) excludedVoteUserIds.add(userId);
      else excludedVoteUserIds.delete(userId);
      renderVote();
    }
  });

  document.querySelector("#predictionEvaluateButton")?.addEventListener("click", handlePredictionEvaluate);
  document.querySelector("#predictionDrawButton")?.addEventListener("click", handlePredictionDraw);
  document.querySelector("#predictionRefreshButton")?.addEventListener("click", () => {
    if (adminToken) loadLivePredictions();
  });

  document.addEventListener("click", (event) => {
    const sectionButton = event.target.closest("[data-admin-section]");
    if (sectionButton) {
      openSection(sectionButton.dataset.adminSection);
      return;
    }

    const videoBtn = event.target.closest("[data-video-action]");
    if (videoBtn) {
      handleVideoAction(videoBtn.dataset.videoId, videoBtn.dataset.videoAction);
      return;
    }

    const reportBtn = event.target.closest("[data-report-action]");
    if (reportBtn) {
      handleReportAction(reportBtn.dataset.reportId, reportBtn.dataset.reportAction);
      return;
    }

    const commentBtn = event.target.closest("[data-comment-action]");
    if (commentBtn) {
      handleCommentAction(commentBtn.dataset.commentId, commentBtn.dataset.commentAction);
      return;
    }

    const voteBtn = event.target.closest("[data-vote-step]");
    if (voteBtn) {
      handleVoteStep(voteBtn.dataset.voteStep);
      return;
    }

    const userBtn = event.target.closest("[data-user-action]");
    if (userBtn) {
      handleUserAction(userBtn.dataset.userId, userBtn.dataset.userAction);
      return;
    }

    const restrictedBtn = event.target.closest("[data-restricted-action]");
    if (restrictedBtn) {
      handleRestrictedUserAction(restrictedBtn.dataset.userId, restrictedBtn.dataset.restrictedAction);
      return;
    }

    const payoutAction = event.target.closest("[data-payout-action]");
    if (payoutAction) {
      handlePayoutAction(payoutAction.dataset.payoutAction, payoutAction.dataset.payoutId);
    }
  });

  let searchTimer;
  document.querySelector("#adminSearch").addEventListener("input", (event) => {
    filterRows(event.target.value);
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
      if (adminToken && document.querySelector("#users.is-visible")) {
        loadUserSections(event.target.value);
      }
    }, 350);
  });
}

function renderAdminProfile(admin = currentAdmin) {
  const nameEl = document.querySelector("#adminProfileName");
  const roleEl = document.querySelector("#adminProfileRole");
  const metaEl = document.querySelector("#adminProfileMeta");
  if (!nameEl || !roleEl || !metaEl) return;

  if (!admin) {
    nameEl.textContent = "관리자";
    roleEl.textContent = "현재 권한";
    metaEl.textContent = "로그인 후 표시됩니다";
    return;
  }

  const roleLabel = adminRoleLabels[admin.role] || admin.role || "관리자";
  nameEl.textContent = admin.name || roleLabel;
  roleEl.textContent = roleLabel;
  metaEl.textContent = `번호 ${admin.adminNumber || "-"} · ${roleLabel}`;
}

function updateAdminPasswordUi() {
  const notice = document.querySelector("#adminPasswordChangeNotice");
  const badge = document.querySelector("#adminPasswordStatusBadge");
  if (notice) notice.hidden = !adminPasswordChangeRequired;
  if (badge) {
    badge.textContent = adminPasswordChangeRequired ? "변경 필요" : "3개월 주기";
    badge.className = `status ${adminPasswordChangeRequired ? "danger" : "warn"}`;
  }
}

function clearAdminSessionState() {
  adminToken = "";
  currentAdmin = null;
  adminPasswordChangeRequired = false;
  excludedVoteUserIds.clear();
  removedCandidateUserIds.clear();
  sessionStorage.removeItem(ADMIN_TOKEN_KEY);
  livePayouts = [];
  liveVideos = [];
  liveReports = [];
  liveComments = [];
  liveCandidates = [];
  liveUsers = [];
  liveRestrictedUsers = [];
  liveChallenge = null;
  livePredictions = [];
  predictionSummary = null;
  dashboardSummary = null;
  renderAdminProfile(null);
  updateAdminPasswordUi();
  renderAdmin();
}

async function applyAdminSession(data, { loadData = true } = {}) {
  adminToken = data.token || adminToken;
  if (adminToken) sessionStorage.setItem(ADMIN_TOKEN_KEY, adminToken);
  currentAdmin = data.admin || currentAdmin;
  adminPasswordChangeRequired = Boolean(data.passwordChangeRequired);
  document.body.classList.remove("admin-locked");
  renderAdminProfile(currentAdmin);
  updateAdminPasswordUi();

  if (adminPasswordChangeRequired) {
    openSection("permissions");
    showToast("비밀번호 변경이 필요합니다. 계정 보안에서 새 비밀번호를 설정해 주세요.");
    return;
  }

  if (loadData) await loadAllAdminData();
}

async function handleAdminLogout() {
  if (!confirm("로그아웃 하시겠습니까?")) return;
  try {
    if (adminToken) {
      await adminApiRequest("/api/admin/auth/logout", { method: "POST" });
    }
  } catch {
    // 로컬 세션은 항상 정리
  }
  clearAdminSessionState();
  document.body.classList.add("admin-locked");
  showToast("로그아웃 완료");
}

async function handleAdminChangePassword(event) {
  event.preventDefault();
  const errorEl = document.querySelector("#adminPasswordChangeError");
  const currentPassword = document.querySelector("#adminCurrentPassword")?.value || "";
  const newPassword = document.querySelector("#adminNewPassword")?.value || "";
  const confirmPassword = document.querySelector("#adminNewPasswordConfirm")?.value || "";

  if (errorEl) errorEl.textContent = "";
  if (newPassword.length < 8) {
    if (errorEl) errorEl.textContent = "새 비밀번호는 8자 이상이어야 합니다";
    return;
  }
  if (newPassword !== confirmPassword) {
    if (errorEl) errorEl.textContent = "새 비밀번호 확인이 일치하지 않습니다";
    return;
  }

  try {
    const data = await adminApiRequest("/api/admin/auth/change-password", {
      method: "POST",
      body: JSON.stringify({ currentPassword, newPassword })
    });
    adminPasswordChangeRequired = false;
    if (data.token) {
      adminToken = data.token;
      sessionStorage.setItem(ADMIN_TOKEN_KEY, adminToken);
    }
    if (data.admin) currentAdmin = data.admin;
    renderAdminProfile(currentAdmin);
    updateAdminPasswordUi();
    document.querySelector("#adminPasswordForm")?.reset();
    showToast("비밀번호가 변경되었습니다");
    await loadAllAdminData();
  } catch (err) {
    if (errorEl) errorEl.textContent = err.message || "비밀번호 변경에 실패했습니다";
  }
}

async function handleAdminLogin() {
  const adminNumber = document.querySelector("#adminNumber").value.trim();
  const adminPassword = document.querySelector("#adminPassword").value.trim();
  const error = document.querySelector("#adminLoginError");

  try {
    const data = await adminApiRequest("/api/admin/auth/login", {
      method: "POST",
      body: JSON.stringify({ adminNumber, password: adminPassword })
    });
    error.textContent = "";
    await applyAdminSession(data);
    if (!adminPasswordChangeRequired) {
      showToast(`${data.admin?.name || "관리자"} 로그인 완료`);
    }
    return;
  } catch (err) {
    error.textContent = "로그인에 실패했습니다";
  }
}

async function tryRestoreAdminSession() {
  if (!adminToken) return;
  try {
    const data = await adminApiRequest("/api/admin/auth/me");
    await applyAdminSession({ ...data, token: adminToken }, { loadData: !data.passwordChangeRequired });
  } catch (err) {
    if (err.code === "PASSWORD_CHANGE_REQUIRED") {
      adminPasswordChangeRequired = true;
      document.body.classList.remove("admin-locked");
      updateAdminPasswordUi();
      openSection("permissions");
      return;
    }
    clearAdminSessionState();
    document.body.classList.add("admin-locked");
  }
}

function setAdminConnectionStatus(message, level = "warn") {
  const el = document.querySelector("#adminConnectionStatus");
  if (!el) return;
  el.textContent = message;
  el.className = `login-status is-${level}`;
}

async function checkAdminApiConnection() {
  if (window.location.protocol === "file:") {
    setAdminConnectionStatus(
      "파일로 열면 API에 연결되지 않습니다. 주소창에 http://localhost:8080/admin.html 을 입력하세요.",
      "bad"
    );
    return false;
  }

  try {
    const response = await fetch(`${API_BASE}/health`, { method: "GET" });
    const data = await response.json().catch(() => ({}));
    if (!response.ok || !data.ok) {
      setAdminConnectionStatus("API 서버(localhost:3000) 응답이 이상합니다.", "bad");
      return false;
    }
    setAdminConnectionStatus(`API 서버 연결됨 (${API_BASE})`, "ok");
    return true;
  } catch {
    setAdminConnectionStatus(
      "API 서버(localhost:3000)에 연결되지 않습니다. showup-server를 켠 뒤 새로고침하세요.",
      "bad"
    );
    return false;
  }
}

renderAdmin();
bindEvents();
checkAdminApiConnection();
tryRestoreAdminSession();
setInterval(updateVotePhaseUi, 30000);
