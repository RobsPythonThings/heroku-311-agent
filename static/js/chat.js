/**
 * 311 AI Chat Application - Frontend with Smart Image Compression
 */

class ChatApp {
    constructor() {
        this.chatMessages = document.getElementById('chat-messages');
        this.chatInput = document.getElementById('chat-input');
        this.sendButton = document.getElementById('send-button');
        this.photoButton = document.getElementById('photo-button');
        this.photoInput = document.getElementById('photo-input');
        this.photoPreview = document.getElementById('photo-preview');
        this.conversation = [];
        this.isTyping = false;
        this.currentPhoto = null;
        this.MAX_SIZE_BYTES = 5 * 1024 * 1024;
        this.MAX_DIMENSION = 1920;
        this.COMPRESSION_QUALITY = 0.85;
        this.setupEventListeners();
        this.addMessage("Hello! I'm your 311 AI Assistant. I can help you report issues like potholes, graffiti, streetlight outages, and more. What can I help you with today?", 'assistant');
    }
    
    setupEventListeners() {
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
    
    async sendMessage() {
        const message = this.chatInput.value.trim();
        if (!message && !this.currentPhoto) return;
        if (this.isTyping) return;
        this.addMessage(message, 'user', this.currentPhoto);
        const photoToSend = this.currentPhoto;
        this.chatInput.value = '';
        this.clearPhoto();
        this.conversation.push({role: 'user', content: message, photo: photoToSend});
        this.showTypingIndicator();
        try {
            const response = await fetch('/chat', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({
                    message: message,
                    conversation: this.conversation.map(msg => ({role: msg.role, content: msg.content})),
                    photo: photoToSend
                })
            });
            this.hideTypingIndicator();
            if (response.ok) {
                const data = await response.json();
                this.addMessage(data.response, 'assistant');
                this.conversation.push({role: 'assistant', content: data.response});
            } else {
                let errorMessage = 'Sorry, I encountered an error. Please try again.';
                try {
                    const errorData = await response.json();
                    if (errorData.error) errorMessage = errorData.error;
                } catch (e) {}
                this.addMessage(errorMessage, 'assistant');
            }
        } catch (error) {
            this.hideTypingIndicator();
            console.error('Error sending message:', error);
            this.addMessage('Sorry, I encountered an error connecting to the server. Please try again.', 'assistant');
        }
    }
    
    addMessage(text, sender, photo = null) {
        const messageDiv = document.createElement('div');
        messageDiv.className = 'message ' + sender + '-message';
        const contentDiv = document.createElement('div');
        contentDiv.className = 'message-content';
        if (photo && sender === 'user') {
            const photoData = typeof photo === 'object' ? photo.compressed_data || photo.data : photo;
            const mediaType = typeof photo === 'object' ? photo.media_type : 'image/jpeg';
            contentDiv.innerHTML += '<img src="data:' + mediaType + ';base64,' + photoData + '" style="max-width: 200px; border-radius: 8px; margin-bottom: 8px; display: block;">';
        }
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
        typingDiv.innerHTML = '<div class="typing-indicator"><span></span><span></span><span></span></div>';
        this.chatMessages.appendChild(typingDiv);
        this.scrollToBottom();
    }
    
    hideTypingIndicator() {
        this.isTyping = false;
        this.sendButton.disabled = false;
        const typingIndicator = document.getElementById('typing-indicator');
        if (typingIndicator) typingIndicator.remove();
    }
    
    async handlePhotoSelect(event) {
        const file = event.target.files[0];
        if (!file) return;
        if (!file.type.startsWith('image/')) {
            alert('Please select an image file');
            return;
        }
        const fileSizeMB = file.size / (1024 * 1024);
        try {
            if (fileSizeMB > 3) this.showPhotoPreview('', file.type, true);
            const originalBase64 = await this.fileToBase64(file);
            let compressedData = originalBase64;
            let needsCompression = file.size > this.MAX_SIZE_BYTES;
            if (needsCompression) {
                console.log('Image is ' + fileSizeMB.toFixed(2) + ' MB, compressing...');
                compressedData = await this.compressImage(file);
                const compressedSize = (compressedData.length * 3) / 4;
                const compressedMB = compressedSize / (1024 * 1024);
                console.log('Compressed to ' + compressedMB.toFixed(2) + ' MB');
                if (compressedSize > this.MAX_SIZE_BYTES) {
                    alert('Image is too large (' + compressedMB.toFixed(1) + ' MB even after compression). Please use a smaller image.');
                    this.photoInput.value = '';
                    return;
                }
            }
            this.currentPhoto = {
                compressed_data: compressedData,
                original_data: originalBase64,
                media_type: file.type,
                was_compressed: needsCompression
            };
            this.showPhotoPreview(compressedData, file.type, false);
        } catch (error) {
            console.error('Error processing photo:', error);
            alert('Error processing photo. Please try again with a different image.');
            this.photoInput.value = '';
        }
    }
    
    fileToBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result.split(',')[1]);
            reader.onerror = reject;
            reader.readAsDataURL(file);
        });
    }
    
    async compressImage(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = (e) => {
                const img = new Image();
                img.onload = () => {
                    let width = img.width;
                    let height = img.height;
                    if (width > this.MAX_DIMENSION || height > this.MAX_DIMENSION) {
                        if (width > height) {
                            height = Math.round((height * this.MAX_DIMENSION) / width);
                            width = this.MAX_DIMENSION;
                        } else {
                            width = Math.round((width * this.MAX_DIMENSION) / height);
                            height = this.MAX_DIMENSION;
                        }
                    }
                    const canvas = document.createElement('canvas');
                    canvas.width = width;
                    canvas.height = height;
                    const ctx = canvas.getContext('2d');
                    ctx.drawImage(img, 0, 0, width, height);
                    const compressedDataUrl = canvas.toDataURL(file.type, this.COMPRESSION_QUALITY);
                    resolve(compressedDataUrl.split(',')[1]);
                };
                img.onerror = () => reject(new Error('Failed to load image for compression'));
                img.src = e.target.result;
            };
            reader.onerror = () => reject(new Error('Failed to read image file'));
            reader.readAsDataURL(file);
        });
    }
    
    showPhotoPreview(base64, media_type, isLoading) {
        if (isLoading) {
            this.photoPreview.innerHTML = '<div style="padding: 20px; text-align: center;"><div>Processing large image...</div></div>';
        } else {
            this.photoPreview.innerHTML = '<div style="position: relative; display: inline-block;"><img src="data:' + media_type + ';base64,' + base64 + '" alt="Selected photo"><button onclick="chatApp.clearPhoto()" style="position: absolute; top: 5px; right: 5px; background: rgba(0,0,0,0.7); color: white; border: none; border-radius: 50%; width: 30px; height: 30px; cursor: pointer; font-size: 20px; line-height: 1;">×</button></div>';
        }
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
document.addEventListener('DOMContentLoaded', function() {
    chatApp = new ChatApp();
});
