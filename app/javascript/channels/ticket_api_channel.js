import consumer from "./consumer"

consumer.subscriptions.create("TicketApiChannel", {
  connected() {
    console.log("Connected to TicketApiChannel")
  },

  disconnected() {
    console.log("Disconnected from TicketApiChannel")
  },

  received(data) {
    console.log("Received data:", data)
    if (data.status === 'success') {
      // Trigger a refresh of the results
      const resultsContainer = document.getElementById('results')
      if (resultsContainer) {
        const currentUrl = new URL(window.location.href)
        fetch(currentUrl.pathname + currentUrl.search)
          .then(response => response.json())
          .then(data => {
            resultsContainer.innerHTML = data.html
          })
          .catch(error => console.error('Error:', error))
      }
    }
  }
}) 