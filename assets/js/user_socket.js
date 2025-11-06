import {Socket} from "phoenix"

// Only initialize chat if user is signed in and in a room
const messagesContainer = document.querySelector("#messages")
const messageInput = document.querySelector("#message-input")
const roomIdInput = document.querySelector("#room-id")
const sendButton = document.querySelector("#send-button")
const usernameDisplay = document.querySelector("#username-display")

if (messagesContainer && messageInput && roomIdInput && sendButton) {
  const roomId = roomIdInput.value

  let socket = new Socket("/socket", {params: {token: window.userToken}})
  socket.connect()

  let channel = socket.channel(`room:${roomId}`, {})

  const sendMessage = () => {
    const message = messageInput.value.trim()

    if (message !== "") {
      channel.push("new_message", {body: message})
      messageInput.value = ""
      // Blur the input to prevent mobile zoom and auto-scroll issues
      messageInput.blur()
      // Prevent immediate refocus
      setTimeout(() => {
        if (document.activeElement === messageInput) {
          messageInput.blur()
        }
      }, 100)
    }
  }

  sendButton.addEventListener("click", sendMessage)
  messageInput.addEventListener("keypress", event => {
    if (event.key === "Enter") {
      sendMessage()
    }
  })

  // Remove "No messages yet" message if it exists
  function removeNoMessagesMessage() {
    const noMessagesMsg = messagesContainer.querySelector('#no-messages-msg')
    if (noMessagesMsg) {
      noMessagesMsg.remove()
    }
  }

  // Display a message in the chat
  function displayMessage(msg) {
    // Remove "No messages yet" message before adding new message
    removeNoMessagesMessage()

    const messageElement = document.createElement("div")
    messageElement.className = "mb-2 p-3 message-bubble rounded-lg fade-in"

    // Format timestamp if present
    let timeStr = ""
    if (msg.timestamp) {
      const date = new Date(msg.timestamp)
      timeStr = `<span class="text-xs text-base-content/50 ml-2">${date.toLocaleTimeString()}</span>`
    }

    // Make username clickable if user_id is available
    let usernameHtml = ""
    if (msg.user_id) {
      usernameHtml = `<a href="/user/${msg.user_id}" class="font-bold text-primary hover:underline">${escapeHtml(msg.username)}</a>:`
    } else {
      usernameHtml = `<span class="font-bold text-primary">${escapeHtml(msg.username)}:</span>`
    }

    messageElement.innerHTML = `
      ${usernameHtml}
      <span class="ml-2">${escapeHtml(msg.body)}</span>
      ${timeStr}
    `

    messagesContainer.appendChild(messageElement)
    messagesContainer.scrollTop = messagesContainer.scrollHeight
  }

  // Display join notification
  function displayJoinNotification(username) {
    const notificationElement = document.createElement("div")
    notificationElement.className = "mb-2 p-2 glass-panel rounded-lg text-center fade-in"
    notificationElement.innerHTML = `
      <span class="text-sm neon-cyan italic">✨ ${escapeHtml(username)} has joined the room</span>
    `
    messagesContainer.appendChild(notificationElement)
    messagesContainer.scrollTop = messagesContainer.scrollHeight
  }

  channel.on("new_message", msg => {
    displayMessage(msg)
  })

  // Reload members when someone joins
  channel.on("user_joined", msg => {
    displayJoinNotification(msg.username)
    loadMembers()
  })

  channel.join()
    .receive("ok", resp => {
      console.log("Joined successfully", resp)

      // Display username
      if (usernameDisplay && resp.username) {
        usernameDisplay.textContent = `Signed in as: ${resp.username}`
      }

      // Clear loading message
      messagesContainer.innerHTML = ""

      // Display message history
      if (resp.messages && resp.messages.length > 0) {
        resp.messages.forEach(msg => displayMessage(msg))
      } else {
        const welcomeMsg = document.createElement("p")
        welcomeMsg.className = "text-base-content/60 text-sm"
        welcomeMsg.id = "no-messages-msg"
        welcomeMsg.textContent = "No messages yet. Start the conversation!"
        messagesContainer.appendChild(welcomeMsg)
      }

      // Load and update member count
      loadMembers()
    })
    .receive("error", resp => {
      console.log("Unable to join", resp)
      const reason = (resp && (resp.reason || resp.error || resp.message)) ? String(resp.reason || resp.error || resp.message) : "Please try again."
      messagesContainer.innerHTML = `
        <div class="flex items-center justify-center h-[60vh]">
          <div class="glass-card border border-error/30 rounded-2xl p-6 sm:p-8 text-center max-w-md w-full shadow-lg fade-in">
            <div class="mx-auto mb-3 sm:mb-4 inline-flex h-12 w-12 items-center justify-center rounded-full bg-error/10 text-error">✖</div>
            <h3 class="text-lg sm:text-xl font-semibold mb-2">Unable to join room</h3>
            <p class="text-sm sm:text-base text-base-content/70 mb-4">${escapeHtml(reason)}</p>
            <div class="flex flex-col sm:flex-row gap-2 justify-center">
              <button id="retry-join" class="btn btn-primary">Retry</button>
              <a href="/" class="btn btn-outline">Leave</a>
            </div>
          </div>
        </div>
      `
      const retryBtn = document.getElementById('retry-join')
      if (retryBtn) {
        retryBtn.addEventListener('click', () => {
          window.location.reload()
        })
      }
    })

  // Function to load and display members
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
        console.error('Error loading members:', error)
      })
  }

  function updateMembersList(members) {
    const membersList = document.getElementById('members-list')
    if (membersList) {
      if (members.length === 0) {
        membersList.innerHTML = '<p class="text-base-content/60 text-sm">No members yet.</p>'
      } else {
        membersList.innerHTML = members.map(member => {
          const roleColor = member.role === 'admin' ? 'badge-primary' :
                           member.role === 'editor' ? 'badge-secondary' :
                           'badge-ghost'
          return `
            <div class="flex items-center justify-between p-3 glass-panel rounded-lg cyber-hover">
              <a href="/user/${member.id}" class="font-medium truncate neon-cyan hover:underline">${escapeHtml(member.name)}</a>
              <span class="badge ${roleColor} badge-sm">${escapeHtml(member.role)}</span>
            </div>
          `
        }).join('')
      }
    }
  }

  function updateMembersCount(count) {
    const membersCount = document.getElementById('members-count')
    if (membersCount) {
      membersCount.textContent = count
    }
  }
}

function escapeHtml(text) {
  const map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;'
  }
  return text.replace(/[&<>"']/g, m => map[m])
}

export default socket
