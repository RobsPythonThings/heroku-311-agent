class ChatApp {
    constructor() {
        this.conversationHistory = [];
        this.currentPhoto = null;
        this.isTyping = false;
        
        this.chatBubble = document.getElementById('chat-bubble');
        this.chatWindow = document.getElementById('chat-window');
        this.closeButton = document.getElementById('close-chat');
        this.chatMessages = document.getElementById('chat-messages');
        this.chatInput = document.getElementById('chat-input');
        this.sendButton = document.getElementById('send-button');
        this.photoButton = document.getElementById('photo-button');
        this.photoInput = document.getElementById('photo-input');
        this.photoPreview = document.getElementById('photo-preview');
        
        this.initializeEventListeners();
        
        this.conversationHistory.push({
            role: 'assistant',
            content: "Hello! I'm your 311 AI Assistant. I can help you report issues like potholes, graffiti, streetlight outages, and more. What can I help you with today?"
        });
    }
    
    initializeEventListeners() {
        this.chatBubble.addEventListener('click', () => this.openChat());
        this.closeButton.addEventListener('click', () => this.closeChat());
        this.sendButton.addEventListener('click', () => this.sendMessage());
        this.chatInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                this.sendMessage();
            }
        });
        this.photoButton.addEventListener('click', () => this.photoInput.click());
        this.photoInput.addEventListener('change', (e) => this.handlePhotoSelect(e));
    }
    
    openChat() {
        this.chatWindow.classList.remove('hidden');
        this.chatBubble.style.display = 'none';
        this.chatInput.focus();
        this.scrollToBottom();
    }
    
    closeChat() {
        this.chatWindow.classList.add('hidden');
        this.chatBubble.style.display = 'flex';
    }
    
    async sendMessage() {
        const message = this.chatInput.value.trim();
        
        if (!message && !this.currentPhoto) return;
        if (this.isTyping) return;
        
        this.addMessage(message, 'user', this.currentPhoto);
        this.chatInput.value = '';
        
        // Store the full message content that was sent
        const messageContent = message || "Photo attached";
        this.conversationHistory.push({
            role: 'user',
            content: messageContent,
            photo: this.currentPhoto
        });
        
        this.showTypingIndicator();
        
        try {
            const response = await fetch('/chat', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    message: message,
                    conversation_history: this.conversationHistory,
                    photo: this.currentPhoto
                })
            });
            
            const data = await response.json();
            
            this.hideTypingIndicator();
            
            if (data.success) {
                this.addMessage(data.response, 'assistant');
                
                this.conversationHistory.push({
                    role: 'assistant',
                    content: data.response
                });
                
                this.clearPhoto();
            } else {
                this.addMessage('Sorry, I encountered an error. Please try again.', 'assistant');
            }
            
        } catch (error) {
            console.error('Error sending message:', error);
            this.hideTypingIndicator();
            this.addMessage('Sorry, I encountered an error connecting to the server. Please try again.', 'assistant');
        }
    }
    
    addMessage(text, sender, photo = null) {
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${sender}-message`;
        
        const contentDiv = document.createElement('div');
        contentDiv.className = 'message-content';
        
        // Add photo if present
        if (photo && sender === 'user') {
            const photoData = typeof photo === 'object' ? photo.data : photo;
            const mediaType = typeof photo === 'object' ? photo.media_type : 'image/jpeg';
            contentDiv.innerHTML += `<img src="data:${mediaType};base64,${photoData}" style="max-width: 200px; border-radius: 8px; margin-bottom: 8px; display: block;">`;
        }
        
        // Add text if present
        if (text) {
            const formattedText = text.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
            contentDiv.innerHTML += formattedText;
        }
        
        messageDiv.appendChild(contentDiv);
        this.chatMessages.appendChild(messageDiv);
        
        this.scrollToBottom();
    }
    
    showTypingIndicator() {
        this.isTyping = true;
        this.sendButton.disabled = true;
        
        const typingDiv = document.createElement('div');
        typingDiv.className = 'message assistant-message';
        typingDiv.id = 'typing-indicator';
        
        typingDiv.innerHTML = `
            <div class="typing-indicator">
                <span></span>
                <span></span>
                <span></span>
            </div>
        `;
        
        this.chatMessages.appendChild(typingDiv);
        this.scrollToBottom();
    }
    
    hideTypingIndicator() {
        this.isTyping = false;
        this.sendButton.disabled = false;
        
        const typingIndicator = document.getElementById('typing-indicator');
        if (typingIndicator) {
            typingIndicator.remove();
        }
    }
    
    async handlePhotoSelect(event) {
        const file = event.target.files[0];
        if (!file) return;
        
        if (!file.type.startsWith('image/')) {
            alert('Please select an image file');
            return;
        }
        
        if (file.size > 5 * 1024 * 1024) {
            alert('Image size must be less than 5MB');
            return;
        }
        
        try {
            const base64 = await this.fileToBase64(file);
            this.currentPhoto = {
                data: base64,
                media_type: file.type
            };
            this.showPhotoPreview(base64, file.type);
        } catch (error) {
            console.error('Error processing photo:', error);
            alert('Error processing photo. Please try again.');
        }
    }
    
    fileToBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => {
                const base64 = reader.result.split(',')[1];
                resolve(base64);
            };
            reader.onerror = reject;
            reader.readAsDataURL(file);
        });
    }
    
    showPhotoPreview(base64, media_type = 'image/jpeg') {
        this.photoPreview.innerHTML = `
            <div style="position: relative; display: inline-block;">
                <img src="data:${media_type};base64,${base64}" alt="Selected photo">
                <button onclick="chatApp.clearPhoto()" style="position: absolute; top: 5px; right: 5px;">×</button>
            </div>
        `;
        this.photoPreview.classList.remove('hidden');
    }
    
    clearPhoto() {
        this.currentPhoto = null;
        this.photoPreview.classList.add('hidden');
        this.photoPreview.innerHTML = '';
        this.photoInput.value = '';
    }
    
    scrollToBottom() {
        this.chatMessages.scrollTop = this.chatMessages.scrollHeight;
    }
}

let chatApp;
document.addEventListener('DOMContentLoaded', () => {
    chatApp = new ChatApp();
});