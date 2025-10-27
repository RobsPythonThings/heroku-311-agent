// Landing page functionality with diagnostics
console.log('landing.js loading...');

document.addEventListener('DOMContentLoaded', function() {
    console.log('Landing page DOM loaded');
    
    const chatBubble = document.getElementById('chat-bubble');
    const chatWindow = document.getElementById('chat-window');
    const issueCards = document.querySelectorAll('.issue-card');
    
    console.log('chatBubble:', chatBubble);
    console.log('chatWindow:', chatWindow);
    console.log('issueCards found:', issueCards.length);
    
    // Auto-open chat after 2 seconds
    setTimeout(() => {
        console.log('Auto-opening chat...');
        if (chatBubble && !chatWindow.classList.contains('visible')) {
            console.log('Clicking chat bubble');
            chatBubble.click();
        }
    }, 2000);
    
    // Chat bubble click handler
    if (chatBubble) {
        chatBubble.addEventListener('click', function() {
            console.log('Chat bubble clicked!');
            chatWindow.classList.remove('hidden');
            chatWindow.classList.add('visible');
            this.classList.add('hidden');
            console.log('Chat window should now be visible');
        });
    }
    
    // Add click handlers to issue cards
    issueCards.forEach((card, index) => {
        card.addEventListener('click', function() {
            console.log('Issue card clicked:', index);
            const issueLabel = this.querySelector('.issue-label');
            const issueType = issueLabel ? issueLabel.textContent : 'issue';
            console.log('Issue type:', issueType);
            
            // Open chat if not already open
            if (chatWindow.classList.contains('hidden')) {
                console.log('Opening chat window...');
                chatBubble.click();
            }
            
            // Wait a moment for chat to open, then insert the issue type
            setTimeout(() => {
                const chatInput = document.getElementById('chat-input');
                console.log('chatInput:', chatInput);
                if (chatInput) {
                    chatInput.value = `I need to report a ${issueType}`;
                    chatInput.focus();
                    console.log('Set input value');
                }
            }, 300);
        });
    });
    
    console.log('Landing page setup complete');
});

console.log('landing.js loaded');
