// Landing page functionality
document.addEventListener('DOMContentLoaded', function() {
    // Auto-open chat after 2 seconds
    setTimeout(() => {
        const chatBubble = document.getElementById('chat-bubble');
        if (chatBubble && !document.getElementById('chat-window').classList.contains('visible')) {
            chatBubble.click();
        }
    }, 2000);

    // Add click handlers to issue cards
    const issueCards = document.querySelectorAll('.issue-card');
    issueCards.forEach(card => {
        card.addEventListener('click', function() {
            const issueType = this.querySelector('.issue-label').textContent;
            
            // Open chat if not already open
            const chatWindow = document.getElementById('chat-window');
            const chatBubble = document.getElementById('chat-bubble');
            
            if (chatWindow.classList.contains('hidden')) {
                chatBubble.click();
            }
            
            // Wait a moment for chat to open, then insert the issue type
            setTimeout(() => {
                const chatInput = document.getElementById('chat-input');
                if (chatInput) {
                    chatInput.value = `I need to report a ${issueType}`;
                    chatInput.focus();
                }
            }, 300);
        });
    });

    // Remove pulse animation after first interaction
    const chatBubble = document.getElementById('chat-bubble');
    chatBubble.addEventListener('click', function() {
        this.classList.remove('pulse');
    }, { once: true });
});
