/**
 * 311 AI Chat - Deep Diagnostic Version
 */

console.log('chat.js loading...');

class ChatApp {
    constructor() {
        console.log('ChatApp constructor starting...');
        
        try {
            this.chatMessages = document.getElementById('chat-messages');
            console.log('chatMessages:', this.chatMessages);
            
            this.chatInput = document.getElementById('chat-input');
            console.log('chatInput:', this.chatInput);
            
            this.sendButton = document.getElementById('send-button');
            console.log('sendButton:', this.sendButton);
            
            this.photoButton = document.getElementById('photo-button');
            console.log('photoButton:', this.photoButton);
            
            this.photoInput = document.getElementById('photo-input');
            console.log('photoInput:', this.photoInput);
            
            this.photoPreview = document.getElementById('photo-preview');
            console.log('photoPreview:', this.photoPreview);
            
            if (!this.chatMessages || !this.chatInput || !this.sendButton || !this.photoButton || !this.photoInput || !this.photoPreview) {
                console.error('MISSING DOM ELEMENTS!');
                alert('ERROR: Missing DOM elements. Check console.');
                return;
            }
            
            this.conversation = [];
            this.isTyping = false;
            this.currentPhoto = null;
            this.MAX_SIZE_BYTES = 5 * 1024 * 1024;
            this.MAX_DIMENSION = 1920;
            this.COMPRESSION_QUALITY = 0.85;
            
            console.log('About to setup event listeners...');
            this.setupEventListeners();
            console.log('Event listeners setup complete');
            
            console.log('About to add greeting message...');
            this.addMessage("Hello! I'm your 311 AI Assistant. I can help you report issues like potholes, graffiti, streetlight outages, and more. What can I help you with today?", 'assistant');
            console.log('Greeting message added');
            
            console.log('ChatApp constructor complete!');
        } catch (error) {
            console.error('Constructor error:', error);
            alert('Constructor error: ' + error.message);
        }
    }
    
    setupEventListeners() {
        console.log('Setting up event listeners...');
        this.sendButton.addEventListener('click', () => this.sendMessage());
        this.chatInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                this.sendMessage();
            }
        });
        this.photoButton.addEventListener('click', () => {
            console.log('Photo button clicked!');
            this.photoInput.click();
        });
        this.photoInput.addEventListener('change', (e) => this.handlePhotoSelect(e));
        console.log('Event listeners attached');
    }
    
    async sendMessage() {
        console.log('sendMessage called');
        console.log('currentPhoto:', this.currentPhoto);
        const message = this.chatInput.value.trim();
        if (!message && !this.currentPhoto) {
            console.log('No message and no photo - returning');
            return;
        }
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
        messageDiv.className = `message ${sender}-message`;
        const contentDiv = document.createElement('div');
        contentDiv.className = 'message-content';
        if (photo && sender === 'user') {
            const photoData = typeof photo === 'object' ? (photo.compressed_data || photo.data) : photo;
            const mediaType = typeof photo === 'object' ? photo.media_type : 'image/jpeg';
            contentDiv.innerHTML += `<img src="data:${mediaType};base64,${photoData}" style="max-width: 200px; border-radius: 8px; margin-bottom: 8px; display: block;">`;
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
        typingDiv.innerHTML = `<div class="typing-indicator"><span></span><span></span><span></span></div>`;
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
        console.log('=== handlePhotoSelect START ===');
        try {
            console.log('Step 1: Getting file...');
            const file = event.target.files[0];
            console.log('File:', file);
            
            if (!file) {
                console.log('No file selected, returning');
                return;
            }
            
            console.log('Step 2: Checking file type:', file.type);
            if (!file.type.startsWith('image/')) {
                console.log('Not an image!');
                alert('Please select an image file');
                return;
            }
            
            console.log('Step 3: Calculating size...');
            const fileSizeMB = file.size / (1024 * 1024);
            console.log('File size:', fileSizeMB, 'MB');
            
            console.log('Step 4: Entering try block...');
            if (fileSizeMB > 3) {
                console.log('Large file, showing preview...');
                this.showPhotoPreview('', file.type, true);
            }
            
            console.log('Step 5: Converting to base64...');
            const originalBase64 = await this.fileToBase64(file);
            console.log('Base64 length:', originalBase64.length);
            
            console.log('Step 6: Checking if compression needed...');
            let compressedData = originalBase64;
            let needsCompression = file.size > this.MAX_SIZE_BYTES;
            console.log('Needs compression:', needsCompression);
            
            if (needsCompression) {
                console.log('Step 7: Compressing image...');
                compressedData = await this.compressImage(file);
                const compressedSize = (compressedData.length * 3) / 4;
                const compressedMB = compressedSize / (1024 * 1024);
                console.log(`Compressed to ${compressedMB.toFixed(2)} MB`);
                
                if (compressedSize > this.MAX_SIZE_BYTES) {
                    alert(`Image is too large (${compressedMB.toFixed(1)} MB even after compression). Please use a smaller image.`);
                    this.photoInput.value = '';
                    return;
                }
            }
            
            console.log('Step 8: Setting currentPhoto...');
            this.currentPhoto = {
                compressed_data: compressedData,
                original_data: originalBase64,
                media_type: file.type,
                was_compressed: needsCompression
            };
            console.log('currentPhoto set:', this.currentPhoto);
            
            console.log('Step 9: Showing preview...');
            this.showPhotoPreview(compressedData, file.type, false);
            console.log('=== handlePhotoSelect COMPLETE ===');
            
        } catch (error) {
            console.error('=== handlePhotoSelect ERROR ===');
            console.error('Error:', error);
            console.error('Stack:', error.stack);
            alert('Error processing photo: ' + error.message);
            this.photoInput.value = '';
        }
    }
    
    fileToBase64(file) {
        console.log('fileToBase64 called');
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => {
                console.log('FileReader onload');
                resolve(reader.result.split(',')[1]);
            };
            reader.onerror = (error) => {
                console.error('FileReader error:', error);
                reject(error);
            };
            reader.readAsDataURL(file);
        });
    }
    
    async compressImage(file) {
        console.log('🎨 Smart compression starting...');
        const fileSizeMB = file.size / (1024 * 1024);
        console.log('Original size:', fileSizeMB.toFixed(2), 'MB');
        
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = (e) => {
                const img = new Image();
                img.onload = () => {
                    console.log('Image dimensions:', img.width, 'x', img.height);
                    let width = img.width;
                    let height = img.height;
                    
                    // Smart dimension reduction based on file size
                    let maxDimension = this.MAX_DIMENSION;
                    if (fileSizeMB > 8) {
                        maxDimension = 1280; // Aggressive for huge photos
                        console.log('📱 Large photo detected, using 1280px max');
                    }
                    
                    if (width > maxDimension || height > maxDimension) {
                        if (width > height) {
                            height = Math.round((height * maxDimension) / width);
                            width = maxDimension;
                        } else {
                            width = Math.round((width * maxDimension) / height);
                            height = maxDimension;
                        }
                    }
                    console.log('Resized to:', width, 'x', height);
                    
                    const canvas = document.createElement('canvas');
                    canvas.width = width;
                    canvas.height = height;
                    const ctx = canvas.getContext('2d');
                    ctx.drawImage(img, 0, 0, width, height);
                    
                    // Smart quality adjustment
                    let quality = this.COMPRESSION_QUALITY;
                    if (fileSizeMB > 8) {
                        quality = 0.6;
                        console.log('✨ Using aggressive quality (0.6)');
                    } else if (fileSizeMB > 3) {
                        quality = 0.7;
                        console.log('✨ Using moderate quality (0.7)');
                    }
                    
                    let compressedDataUrl = canvas.toDataURL(file.type, quality);
                    let compressedSizeMB = (compressedDataUrl.length * 0.75) / (1024 * 1024);
                    console.log('First pass:', compressedSizeMB.toFixed(2), 'MB');
                    
                    // If still too big, compress more aggressively
                    if (compressedSizeMB > 4.5 && quality > 0.5) {
                        console.log('🔄 Still too large, compressing again...');
                        compressedDataUrl = canvas.toDataURL(file.type, 0.5);
                        compressedSizeMB = (compressedDataUrl.length * 0.75) / (1024 * 1024);
                        console.log('Second pass:', compressedSizeMB.toFixed(2), 'MB');
                    }
                    
                    console.log('✅ Compression complete!');
                    resolve(compressedDataUrl.split(',')[1]);
                };
                img.onerror = (error) => {
                    console.error('Image load error:', error);
                    reject(new Error('Failed to load image for compression'));
                };
                img.src = e.target.result;
            };
            reader.onerror = (error) => {
                console.error('Compress reader error:', error);
                reject(new Error('Failed to read image file'));
            };
            reader.readAsDataURL(file);
        });
    }
    
    showPhotoPreview(base64, media_type = 'image/jpeg', isLoading = false) {
        console.log('showPhotoPreview called, isLoading:', isLoading);
        if (isLoading) {
            this.photoPreview.innerHTML = '<div style="padding: 20px; text-align: center;"><div>✨ Optimizing your photo...</div></div>';
        } else {
            this.photoPreview.innerHTML = `<div style="position: relative; display: inline-block;"><img src="data:${media_type};base64,${base64}" alt="Selected photo"><button onclick="chatApp.clearPhoto()" style="position: absolute; top: 5px; right: 5px; background: rgba(0,0,0,0.7); color: white; border: none; border-radius: 50%; width: 30px; height: 30px; cursor: pointer; font-size: 20px; line-height: 1;">×</button></div>`;
        }
        this.photoPreview.classList.remove('hidden');
        console.log('Preview shown');
    }
    
    clearPhoto() {
        console.log('clearPhoto called');
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
console.log('Setting up DOMContentLoaded listener...');
document.addEventListener('DOMContentLoaded', () => {
    console.log('DOM loaded, creating ChatApp...');
    chatApp = new ChatApp();
    console.log('ChatApp created:', chatApp);
});
console.log('chat.js loaded completely');
