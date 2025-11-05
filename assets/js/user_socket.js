import {Socket} from "phoenix"

// Only initialize chat if user is signed in and in a room
const messagesContainer = document.querySelector("#messages")
const messageInput = document.querySelector("#message-input")
const usernameInput = document.querySelector("#username")
const roomIdInput = document.querySelector("#room-id")
const sendButton = document.querySelector("#send-button")

if (messagesContainer && messageInput && usernameInput && roomIdInput && sendButton) {
  const roomId = roomIdInput.value

  let socket = new Socket("/socket", {params: {token: window.userToken}})
  socket.connect()

  let channel = socket.channel(`room:${roomId}`, {})

  const sendMessage = () => {
    const message = messageInput.value.trim()
    const username = usernameInput.value.trim() || "Anonymous"

    if (message !== "") {
      channel.push("new_message", {body: message, username: username})
      messageInput.value = ""
    }
  }

  sendButton.addEventListener("click", sendMessage)
  messageInput.addEventListener("keypress", event => {
    if (event.key === "Enter") {
      sendMessage()
    }
  })

  // Display a message in the chat
  function displayMessage(msg) {
    const messageElement = document.createElement("div")
    messageElement.className = "mb-2 p-2 bg-base-300 rounded"

    // Format timestamp if present
    let timeStr = ""
    if (msg.timestamp) {
      const date = new Date(msg.timestamp)
      timeStr = `<span class="text-xs text-base-content/50 ml-2">${date.toLocaleTimeString()}</span>`
    }

    messageElement.innerHTML = `
      <span class="font-bold text-primary">${escapeHtml(msg.username)}:</span>
      <span class="ml-2">${escapeHtml(msg.body)}</span>
      ${timeStr}
    `

    messagesContainer.appendChild(messageElement)
    messagesContainer.scrollTop = messagesContainer.scrollHeight
  }

  channel.on("new_message", msg => {
    displayMessage(msg)
  })

  channel.join()
    .receive("ok", resp => {
      console.log("Joined successfully", resp)

      // Clear loading message
      messagesContainer.innerHTML = ""

      // Display message history
      if (resp.messages && resp.messages.length > 0) {
        resp.messages.forEach(msg => displayMessage(msg))
      } else {
        const welcomeMsg = document.createElement("p")
        welcomeMsg.className = "text-base-content/60 text-sm"
        welcomeMsg.textContent = "No messages yet. Start the conversation!"
        messagesContainer.appendChild(welcomeMsg)
      }
    })
    .receive("error", resp => {
      console.log("Unable to join", resp)
      messagesContainer.innerHTML = '<p class="text-error">Unable to join room. Please try again.</p>'
    })
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
