// Sign-in popup functionality
import { initializeFirebaseUI } from './firebaseui';

// Create a popup sign-in modal
export const showSignInPopup = () => {
  // Create modal overlay
  const overlay = document.createElement('div');
  overlay.id = 'sign-in-popup-overlay';
  overlay.style.cssText = `
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.75);
    backdrop-filter: blur(4px);
    z-index: 10000;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 1rem;
    overflow-y: auto;
    -webkit-overflow-scrolling: touch;
  `;

  // Create modal container
  const container = document.createElement('div');
  container.id = 'sign-in-popup-container';
  container.style.cssText = `
    background: #1F2937;
    border-radius: 1rem;
    padding: 1.5rem;
    max-width: 420px;
    width: 100%;
    max-height: calc(100vh - 2rem);
    overflow-y: auto;
    box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
    position: relative;
    color: white;
    margin: auto;
    -webkit-overflow-scrolling: touch;
  `;

  // Create header with padlock icon
  const header = document.createElement('div');
  header.style.cssText = `
    margin-bottom: 1.5rem;
    text-align: center;
  `;
  header.innerHTML = `
    <div style="display: flex; align-items: center; justify-content: center; gap: 0.75rem; margin-bottom: 0.5rem;">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink: 0;">
        <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
        <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
      </svg>
      <h2 style="color: white; font-size: clamp(1.25rem, 4vw, 1.5rem); font-weight: 700; margin: 0;">
        Unlock the full experience
      </h2>
    </div>
    <p style="color: #D1D5DB; font-size: clamp(0.8125rem, 3vw, 0.875rem); margin: 0; line-height: 1.5;">
      Log in or create an account with PriceBreak to get started.
    </p>
  `;

  // Create close button
  const closeButton = document.createElement('button');
  closeButton.innerHTML = '×';
  closeButton.setAttribute('aria-label', 'Close');
  closeButton.style.cssText = `
    position: absolute;
    top: 0.75rem;
    right: 0.75rem;
    background: rgba(255, 255, 255, 0.1);
    border: none;
    font-size: 1.5rem;
    color: white;
    cursor: pointer;
    width: 2.5rem;
    height: 2.5rem;
    min-width: 2.5rem;
    min-height: 2.5rem;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 0.5rem;
    transition: all 0.2s;
    line-height: 1;
    touch-action: manipulation;
    -webkit-tap-highlight-color: transparent;
  `;
  closeButton.onmouseover = () => {
    closeButton.style.background = 'rgba(255, 255, 255, 0.2)';
  };
  closeButton.onmouseout = () => {
    closeButton.style.background = 'rgba(255, 255, 255, 0.1)';
  };
  closeButton.onclick = () => {
    if (overlay.parentNode) {
      document.body.removeChild(overlay);
    }
  };

  // Create FirebaseUI container
  const firebaseuiContainer = document.createElement('div');
  firebaseuiContainer.id = 'firebaseui-popup-container';
  firebaseuiContainer.style.cssText = `
    margin-bottom: 1.5rem;
  `;

  // Create footer with terms and privacy policy
  const footer = document.createElement('div');
  footer.style.cssText = `
    text-align: center;
    padding-top: 1rem;
    border-top: 1px solid rgba(255, 255, 255, 0.1);
    margin-top: 1rem;
  `;
  footer.innerHTML = `
    <p style="color: #9CA3AF; font-size: clamp(0.6875rem, 2.5vw, 0.75rem); margin: 0; line-height: 1.6;">
      By continuing you agree to PriceBreak's 
      <a href="/terms" style="color: #60A5FA; text-decoration: underline; cursor: pointer; touch-action: manipulation;">Terms of Service</a> 
      and 
      <a href="/privacy" style="color: #60A5FA; text-decoration: underline; cursor: pointer; touch-action: manipulation;">Privacy Policy</a>.
    </p>
  `;

  // Assemble modal
  container.appendChild(closeButton);
  container.appendChild(header);
  container.appendChild(firebaseuiContainer);
  container.appendChild(footer);
  overlay.appendChild(container);

  // Close on overlay click
  overlay.onclick = (e) => {
    if (e.target === overlay) {
      document.body.removeChild(overlay);
      restoreScroll();
    }
  };

  // Prevent body scroll when modal is open (better mobile UX)
  const originalOverflow = document.body.style.overflow;
  document.body.style.overflow = 'hidden';
  
  // Restore scroll when modal closes
  const restoreScroll = () => {
    document.body.style.overflow = originalOverflow;
  };
  
  // Update close button to restore scroll
  const originalCloseHandler = closeButton.onclick;
  closeButton.onclick = () => {
    if (overlay.parentNode) {
      document.body.removeChild(overlay);
      restoreScroll();
    }
  };

  // Add to page
  document.body.appendChild(overlay);
  
  // Update overlay styles after appending to ensure responsive styles apply
  // Use requestAnimationFrame to ensure styles are applied
  requestAnimationFrame(() => {
    // The CSS media queries will handle the responsive behavior
    // This ensures the overlay is properly positioned
    if (window.innerWidth < 640) {
      overlay.style.alignItems = 'flex-end';
      overlay.style.padding = '0';
    } else {
      overlay.style.alignItems = 'center';
      overlay.style.padding = '1rem';
    }
  });

  // Add custom styles for FirebaseUI in dark theme with mobile optimization
  const style = document.createElement('style');
  style.textContent = `
    #sign-in-popup-overlay {
      align-items: flex-start;
      padding-top: 2rem;
      padding-bottom: 2rem;
    }
    
    @media (min-width: 640px) {
      #sign-in-popup-overlay {
        align-items: center;
        padding-top: 1rem;
        padding-bottom: 1rem;
      }
    }
    
    #sign-in-popup-container {
      margin-top: auto;
      margin-bottom: auto;
    }
    
    @media (max-width: 640px) {
      #sign-in-popup-container {
        border-radius: 1rem 1rem 0 0;
        max-height: calc(100vh - 2rem);
        padding: 1.25rem;
      }
      
      #sign-in-popup-overlay {
        padding: 0;
        align-items: flex-end;
      }
    }
    
    @media (max-height: 600px) {
      #sign-in-popup-container {
        max-height: 95vh;
        margin-top: 0.5rem;
        margin-bottom: 0.5rem;
      }
    }
    
    #firebaseui-popup-container .firebaseui-container {
      max-width: 100%;
      background: transparent;
    }
    #firebaseui-popup-container .firebaseui-card-content {
      padding: 0;
    }
    #firebaseui-popup-container .firebaseui-title,
    #firebaseui-popup-container .firebaseui-subtitle {
      display: none;
    }
    #firebaseui-popup-container .firebaseui-list-item {
      margin-bottom: 0.75rem;
    }
    #firebaseui-popup-container .firebaseui-button {
      background: #2563EB !important;
      border: none !important;
      border-radius: 0.5rem !important;
      padding: clamp(0.875rem, 3vw, 1rem) 1rem !important;
      font-size: clamp(0.875rem, 3vw, 0.9375rem) !important;
      font-weight: 500 !important;
      color: white !important;
      width: 100% !important;
      transition: all 0.2s !important;
      min-height: 44px !important;
      touch-action: manipulation !important;
      -webkit-tap-highlight-color: transparent !important;
    }
    #firebaseui-popup-container .firebaseui-button:hover {
      background: #1D4ED8 !important;
      transform: translateY(-1px);
      box-shadow: 0 4px 12px rgba(37, 99, 235, 0.4);
    }
    @media (hover: none) {
      #firebaseui-popup-container .firebaseui-button:active {
        background: #1D4ED8 !important;
        transform: scale(0.98);
      }
    }
    #firebaseui-popup-container .firebaseui-idp-google {
      background: white !important;
      color: #1F2937 !important;
    }
    #firebaseui-popup-container .firebaseui-idp-google:hover {
      background: #F9FAFB !important;
    }
    @media (hover: none) {
      #firebaseui-popup-container .firebaseui-idp-google:active {
        background: #F9FAFB !important;
        transform: scale(0.98);
      }
    }
    #firebaseui-popup-container .firebaseui-idp-icon-wrapper {
      display: flex;
      align-items: center;
      justify-content: center;
    }
    #firebaseui-popup-container .firebaseui-idp-text {
      font-size: clamp(0.875rem, 3vw, 0.9375rem) !important;
      font-weight: 500 !important;
    }
    #firebaseui-popup-container .firebaseui-form-actions {
      margin: 0;
    }
    #firebaseui-popup-container .firebaseui-input {
      background: rgba(255, 255, 255, 0.1) !important;
      border: 1px solid rgba(255, 255, 255, 0.2) !important;
      border-radius: 0.5rem !important;
      color: white !important;
      padding: clamp(0.875rem, 3vw, 1rem) !important;
      font-size: 16px !important; /* Prevents zoom on iOS */
      min-height: 44px !important;
    }
    #firebaseui-popup-container .firebaseui-input::placeholder {
      color: #9CA3AF !important;
    }
    #firebaseui-popup-container .firebaseui-label {
      color: #D1D5DB !important;
    }
    #firebaseui-popup-container .firebaseui-error {
      color: #FCA5A5 !important;
      background: rgba(239, 68, 68, 0.1) !important;
      border: 1px solid rgba(239, 68, 68, 0.3) !important;
      border-radius: 0.5rem !important;
      padding: 0.75rem !important;
      font-size: clamp(0.8125rem, 2.5vw, 0.875rem) !important;
    }
  `;
  document.head.appendChild(style);

  // Initialize FirebaseUI in the popup
  setTimeout(() => {
    initializeFirebaseUI('firebaseui-popup-container', {
      callbacks: {
        signInSuccessWithAuthResult: function(authResult: any, redirectUrl?: string) {
          // Close popup on successful sign-in
          if (overlay.parentNode) {
            document.body.removeChild(overlay);
          }
          
          // Get the ID token and send it to our Rails backend
          authResult.user.getIdToken().then((idToken: string) => {
            fetch('/api/auth/login', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${idToken}`
              }
            }).then(response => {
              if (response.ok) {
                console.log('✅ Backend authentication successful');
                // Close popup and update UI without full page reload
                if (overlay.parentNode) {
                  document.body.removeChild(overlay);
                }
                // Trigger a custom event to update UI instead of reloading
                window.dispatchEvent(new CustomEvent('authStateChanged', { detail: { user: authResult.user } }));
                // Small delay then update UI elements
                setTimeout(() => {
                  const signInBtn = document.getElementById('sign-in-btn');
                  const userInfo = document.getElementById('user-info');
                  if (signInBtn) signInBtn.style.display = 'none';
                  if (userInfo) {
                    userInfo.style.display = 'flex';
                    const displayName = authResult.user.displayName || authResult.user.email || 'User';
                    const firstLetter = displayName.charAt(0).toUpperCase();
                    // Generate a color based on the first letter for consistent avatar colors
                    const colors = ['#2563EB', '#7C3AED', '#DC2626', '#059669', '#D97706', '#BE185D', '#0891B2', '#CA8A04'];
                    const colorIndex = firstLetter.charCodeAt(0) % colors.length;
                    const avatarColor = colors[colorIndex];
                    
                    userInfo.innerHTML = `
                      <div class="user-info" style="display: flex; align-items: center; gap: 0.75rem;">
                        <a href="/account" style="display: flex; align-items: center; gap: 0.5rem; text-decoration: none; position: relative;" title="${displayName}">
                          <div style="width: 40px; height: 40px; border-radius: 50%; background: ${avatarColor}; display: flex; align-items: center; justify-content: center; color: white; font-weight: 600; font-size: 1rem; border: 2px solid rgba(255, 255, 255, 0.3); cursor: pointer; transition: all 0.2s;" 
                               onmouseover="this.style.transform='scale(1.1)'; this.style.borderColor='rgba(255,255,255,0.5)'" 
                               onmouseout="this.style.transform='scale(1)'; this.style.borderColor='rgba(255,255,255,0.3)'">
                            ${firstLetter}
                          </div>
                        </a>
                        <button onclick="(function(){const a=typeof firebase!=='undefined'&&firebase.auth?firebase.auth():window.firebaseAuthInstance;if(a){a.signOut().then(()=>{console.log('✅ Signed out successfully');const signInBtn=document.getElementById('sign-in-btn');const userInfo=document.getElementById('user-info');if(signInBtn)signInBtn.style.display='inline-flex';if(userInfo)userInfo.style.display='none';});}})()" 
                                style="display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.5rem 0.75rem; background: rgba(255, 255, 255, 0.1); border-radius: 0.375rem; color: white; border: 1px solid rgba(255, 255, 255, 0.2); cursor: pointer; font-size: 0.875rem; transition: all 0.2s;" 
                                onmouseover="this.style.background='rgba(255,255,255,0.15)'" 
                                onmouseout="this.style.background='rgba(255,255,255,0.1)'">
                          Sign Out
                        </button>
                      </div>
                    `;
                  }
                }, 100);
              } else {
                console.error('❌ Backend authentication failed');
              }
            }).catch(error => {
              console.error('❌ Backend authentication error:', error);
            });
          });

          return false; // Don't redirect automatically
        },
        uiShown: function() {
          // Hide loader if it exists
          const loader = document.getElementById('sign-in-popup-loader');
          if (loader) {
            loader.style.display = 'none';
          }
        }
      }
    });
  }, 100);
};

// Make it available globally
if (typeof window !== 'undefined') {
  (window as any).showSignInPopup = showSignInPopup;
}

