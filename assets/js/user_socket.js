import {Socket} from "phoenix"

const messagesContainer = document.querySelector("#messages")
const messageInput = document.querySelector("#message-input")
const roomIdInput = document.querySelector("#room-id")
const sendButton = document.querySelector("#send-button")
const usernameDisplay = document.querySelector("#username-display")
const userTokenInput = document.querySelector("#user-token")

const joinRoomForm = document.querySelector("#join-room-form")
const joinRoomInput = document.querySelector("#join-room-id")
const copyRoomLinkButton = document.querySelector("#copy-room-link")

if (joinRoomForm && joinRoomInput) {
  joinRoomForm.addEventListener("submit", event => {
    event.preventDefault()
    const roomId = joinRoomInput.value.trim()
    if (roomId) {
      window.location.href = `/room/${encodeURIComponent(roomId)}`
    }
  })
}

if (copyRoomLinkButton) {
  copyRoomLinkButton.addEventListener("click", async () => {
    const roomUrl = copyRoomLinkButton.dataset.roomUrl
    if (!roomUrl || !navigator.clipboard) {
      return
    }

    const previousText = copyRoomLinkButton.textContent
    try {
      await navigator.clipboard.writeText(roomUrl)
      copyRoomLinkButton.textContent = "Copied"
    } catch (_error) {
      copyRoomLinkButton.textContent = "Copy failed"
    }

    window.setTimeout(() => {
      copyRoomLinkButton.textContent = previousText
    }, 1600)
  })
}

if (messagesContainer && messageInput && roomIdInput && sendButton) {
  const roomId = roomIdInput.value
  const userToken = userTokenInput ? userTokenInput.value : null

  let chatSocket = new Socket("/socket", {params: {token: userToken}})
  chatSocket.connect()

  let channel = chatSocket.channel(`room:${roomId}`, {})
  let isSending = false

  const setSendingState = sending => {
    isSending = sending
    messageInput.disabled = sending
    sendButton.disabled = sending
    sendButton.textContent = sending ? "Sending..." : "Send"
  }

  const showTransientError = text => {
    const error = document.createElement("div")
    error.className = "mb-2 rounded-xl border border-error/50 bg-error/20 p-2 text-sm text-error-content"
    error.textContent = text
    messagesContainer.appendChild(error)
    messagesContainer.scrollTop = messagesContainer.scrollHeight

    window.setTimeout(() => {
      error.remove()
    }, 2600)
  }

  const sendMessage = () => {
    const message = messageInput.value.trim()
    if (message === "" || isSending) {
      return
    }

    setSendingState(true)

    channel
      .push("new_message", {body: message})
      .receive("ok", () => {
        messageInput.value = ""
        setSendingState(false)
      })
      .receive("error", err => {
        console.error("Error sending message:", err)
        setSendingState(false)
        showTransientError(err.reason || "Failed to send message")
      })
      .receive("timeout", () => {
        console.error("Message send timeout")
        setSendingState(false)
        showTransientError("Message send timeout. Please try again.")
      })
  }

  sendButton.addEventListener("click", sendMessage)
  messageInput.addEventListener("keypress", event => {
    if (event.key === "Enter") {
      sendMessage()
    }
  })

  function removeNoMessagesMessage() {
    const noMessagesMsg = messagesContainer.querySelector("#no-messages-msg")
    if (noMessagesMsg) {
      noMessagesMsg.remove()
    }
  }

  function displayMessage(msg) {
    removeNoMessagesMessage()

    const messageElement = document.createElement("div")
    messageElement.className = "message-bubble mb-2"

    let timeStr = ""
    if (msg.timestamp) {
      const date = new Date(msg.timestamp)
      timeStr = `<span class="ml-2 text-xs text-base-content/60">${date.toLocaleTimeString([], {hour: "2-digit", minute: "2-digit"})}</span>`
    }

    let usernameHtml = ""
    if (msg.user_id) {
      usernameHtml = `<a href="/user/${msg.user_id}" class="font-semibold text-secondary hover:underline">${escapeHtml(msg.username)}</a>`
    } else {
      usernameHtml = `<span class="font-semibold text-secondary">${escapeHtml(msg.username)}</span>`
    }

    messageElement.innerHTML = `${usernameHtml}<span class="mx-1 text-base-content/40">·</span><span class="text-base-content">${escapeHtml(msg.body)}</span>${timeStr}`
    messagesContainer.appendChild(messageElement)
    messagesContainer.scrollTop = messagesContainer.scrollHeight
  }

  function displayJoinNotification(username) {
    const wrapper = document.createElement("div")
    wrapper.className = "mb-2 text-center"
    wrapper.innerHTML = `<span class="notice-bubble">${escapeHtml(username)} joined the room</span>`
    messagesContainer.appendChild(wrapper)
    messagesContainer.scrollTop = messagesContainer.scrollHeight
  }

  channel.on("new_message", msg => {
    displayMessage(msg)
  })

  channel.on("user_joined", msg => {
    displayJoinNotification(msg.username)
    loadMembers()
  })

  channel
    .join()
    .receive("ok", resp => {
      if (usernameDisplay && resp.username) {
        usernameDisplay.textContent = `Signed in as ${resp.username}`
      }

      messagesContainer.innerHTML = ""

      if (resp.messages && resp.messages.length > 0) {
        resp.messages.forEach(msg => displayMessage(msg))
      } else {
        const welcomeMsg = document.createElement("p")
        welcomeMsg.className = "text-sm text-base-content/70"
        welcomeMsg.id = "no-messages-msg"
        welcomeMsg.textContent = "No messages yet. Start the conversation."
        messagesContainer.appendChild(welcomeMsg)
      }

      loadMembers()
    })
    .receive("error", resp => {
      const reason = (resp && (resp.reason || resp.error || resp.message))
        ? String(resp.reason || resp.error || resp.message)
        : "Please try again."

      messagesContainer.innerHTML = `
        <div class="mx-auto mt-12 max-w-lg rounded-3xl border border-error/40 bg-error/15 p-6 text-center">
          <h3 class="text-lg font-semibold">Unable to join room</h3>
          <p class="mt-2 text-sm text-base-content/75">${escapeHtml(reason)}</p>
          <div class="mt-4 flex flex-col justify-center gap-2 sm:flex-row">
            <button id="retry-join" class="ui-btn ui-btn-primary">Retry</button>
            <a href="/" class="ui-btn ui-btn-soft">Leave</a>
          </div>
        </div>
      `

      const retryBtn = document.getElementById("retry-join")
      if (retryBtn) {
        retryBtn.addEventListener("click", () => {
          window.location.reload()
        })
      }
    })

  function loadMembers() {
    fetch(`/room/${roomId}/members`)
      .then(response => response.json())
      .then(data => {
        if (data.members) {
          updateMembersList(data.members)
          updateMembersCount(data.members.length)
        }
      })
      .catch(error => {
        console.error("Error loading members:", error)
      })
  }

  function updateMembersList(members) {
    const membersList = document.getElementById("members-list")
    if (!membersList) {
      return
    }

    if (members.length === 0) {
      membersList.innerHTML = '<p class="text-sm text-base-content/70">No members yet.</p>'
      return
    }

    membersList.innerHTML = members
      .map(member => {
        const roleClass = member.role === "admin"
          ? "ui-badge-admin"
          : member.role === "editor"
            ? "ui-badge-editor"
            : "ui-badge-member"

        return `
          <div class="ui-card flex items-center justify-between gap-3 rounded-2xl p-3">
            <a href="/user/${member.id}" class="truncate font-medium text-base-content hover:underline">${escapeHtml(member.name)}</a>
            <span class="ui-badge ${roleClass}">${escapeHtml(member.role)}</span>
          </div>
        `
      })
      .join("")
  }

  function updateMembersCount(count) {
    const membersCount = document.getElementById("members-count")
    if (membersCount) {
      membersCount.textContent = count
    }
  }
}

function escapeHtml(text) {
  const value = typeof text === "string" ? text : String(text || "")
  const map = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#039;"
  }
  return value.replace(/[&<>"']/g, m => map[m])
}
