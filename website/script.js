// ============================================
// RecipeFinder Website JavaScript
// ============================================

document.addEventListener('DOMContentLoaded', () => {
    initThemeToggle();
    initNotifyForm();
    initScrollAnimations();
    initCookieConsent();
    initSmoothScroll();
    initShowMoreFeatures();
});

// ============================================
// Theme Toggle
// ============================================

function initThemeToggle() {
    const themeToggle = document.getElementById('themeToggle');
    const themeIcon = themeToggle.querySelector('.theme-icon');
    const root = document.documentElement;
    
    // Check for saved theme preference, otherwise respect system preference
    const savedTheme = localStorage.getItem('theme');
    const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    
    let currentTheme;
    if (savedTheme) {
        currentTheme = savedTheme;
    } else {
        currentTheme = systemPrefersDark ? 'dark' : 'light';
    }
    
    root.setAttribute('data-theme', currentTheme);
    updateThemeIcon(currentTheme, themeIcon);
    
    themeToggle.addEventListener('click', () => {
        const currentTheme = root.getAttribute('data-theme');
        const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
        
        root.setAttribute('data-theme', newTheme);
        
        // Only save to localStorage if cookies accepted
        const cookieConsent = localStorage.getItem('cookieConsent');
        if (cookieConsent === 'accepted') {
            localStorage.setItem('theme', newTheme);
        }
        
        updateThemeIcon(newTheme, themeIcon);
        
        // Add a subtle animation
        themeToggle.style.transform = 'translateY(-50%) rotate(360deg)';
        setTimeout(() => {
            themeToggle.style.transform = 'translateY(-50%)';
        }, 300);
    });
    
    // Listen for system theme changes
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
        if (!localStorage.getItem('theme')) {
            const newTheme = e.matches ? 'dark' : 'light';
            root.setAttribute('data-theme', newTheme);
            updateThemeIcon(newTheme, themeIcon);
        }
    });
}

function updateThemeIcon(theme, iconElement) {
    iconElement.textContent = theme === 'dark' ? '☀️' : '🌙';
    iconElement.setAttribute('aria-label', `Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`);
}

// ============================================
// Notify Form
// ============================================

function initNotifyForm() {
    const form = document.getElementById('notifyForm');
    const message = document.getElementById('formMessage');
    const button = form.querySelector('button');
    const input = form.querySelector('input[type="email"]');
    
    // Comprehensive email validation regex
    const emailRegex = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

    // Validate email format
    function validateEmail(email) {
        // Remove whitespace
        email = email.trim();
        
        // Check regex pattern
        if (!emailRegex.test(email)) {
            return false;
        }
        
        // Additional checks
        const [localPart, domain] = email.split('@');
        
        // Check local part (before @)
        if (localPart.length === 0 || localPart.length > 64) {
            return false;
        }
        
        // Check domain part (after @)
        if (domain.length === 0 || domain.length > 255) {
            return false;
        }
        
        // Check for consecutive dots
        if (email.includes('..')) {
            return false;
        }
        
        // Check domain has at least one dot
        if (!domain.includes('.')) {
            return false;
        }
        
        return true;
    }
    
    // Real-time validation on input
    input.addEventListener('input', () => {
        const email = input.value.trim();
        
        if (email.length === 0) {
            // Empty input - reset to neutral state
            input.style.borderColor = 'rgba(255, 255, 255, 0.3)';
            message.textContent = '';
            return;
        }
        
        if (validateEmail(email)) {
            // Valid email - green border
            input.style.borderColor = '#10b981';
            message.textContent = '';
        } else {
            // Invalid email - red border
            input.style.borderColor = '#ef4444';
            if (email.includes('@')) {
                message.textContent = '⚠ Please enter a valid email address';
            } else {
                message.textContent = '';
            }
            message.style.color = '#ef4444';
        }
    });
    
    // Validation on blur (when user clicks away)
    input.addEventListener('blur', () => {
        const email = input.value.trim();
        
        if (email.length > 0 && !validateEmail(email)) {
            input.style.borderColor = '#ef4444';
            message.textContent = '⚠ Please enter a valid email address';
            message.style.color = '#ef4444';
        } else if (email.length === 0) {
            input.style.borderColor = 'rgba(255, 255, 255, 0.3)';
            message.textContent = '';
        }
    });

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const email = input.value.trim();
        
        // Validate email before submission
        if (!validateEmail(email)) {
            message.textContent = '⚠ Please enter a valid email address';
            message.style.color = '#ef4444';
            input.style.borderColor = '#ef4444';
            input.focus();
            return;
        }
        
        // Check honeypot (if filled, it's a bot)
        const botcheck = form.querySelector('[name="botcheck"]');
        if (botcheck && botcheck.value !== '') {
            // Silently fail for bots
            message.textContent = '✓ Welcome to the community! We\'ll see you on launch day.';
            message.style.color = 'var(--text-primary)';
            form.reset();
            return;
        }
        
        // Disable button and show loading state
        button.disabled = true;
        button.textContent = 'Adding...';
        message.textContent = '';
        
        try {
            // Create FormData and ensure proper formatting
            const formData = new FormData(form);
            
            // Submit to Web3Forms with proper headers
            const response = await fetch('https://api.web3forms.com/submit', {
                method: 'POST',
                headers: {
                    'Accept': 'application/json'
                },
                body: formData
            });
            
            const data = await response.json();
            
            if (response.ok && data.success) {
                message.textContent = '✓ Welcome to the community! We\'ll see you on launch day.';
                message.style.color = 'var(--text-primary)';
                input.style.borderColor = 'rgba(255, 255, 255, 0.3)';
                form.reset();
                
                // Clear message after 6 seconds
                setTimeout(() => {
                    message.textContent = '';
                }, 6000);
            } else {
                // Handle specific error messages
                let errorMessage = '⚠ Oops! Something went wrong. Please try again.';
                
                if (data.message && data.message.includes('spam')) {
                    errorMessage = '⚠ Please wait a moment and try again.';
                }
                
                throw new Error(data.message || 'Form submission failed');
            }
            
            // Reset button
            button.disabled = false;
            button.textContent = 'Notify Me';
            
        } catch (error) {
            message.textContent = '⚠ Oops! Something went wrong. Please try again.';
            message.style.color = '#ef4444';
            button.disabled = false;
            button.textContent = 'Notify Me';
            
            console.error('Subscription error:', error);
        }
    });
}

// ============================================
// Scroll Animations
// ============================================

function initScrollAnimations() {
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, {
        threshold: 0.1
    });

    // Observe features
    document.querySelectorAll('.feature').forEach(feature => {
        feature.style.opacity = '0';
        feature.style.transform = 'translateY(20px)';
        feature.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(feature);
    });

    // Observe notify section
    const notifySection = document.querySelector('.notify-section');
    if (notifySection) {
        notifySection.style.opacity = '0';
        notifySection.style.transform = 'translateY(20px)';
        notifySection.style.transition = 'opacity 0.8s ease, transform 0.8s ease';
        observer.observe(notifySection);
    }
}

// ============================================
// Logo Interaction (Optional Easter Egg)
// ============================================

const logo = document.querySelector('.logo');
if (logo) {
    logo.addEventListener('click', () => {
        logo.style.transform = 'scale(0.95)';
        setTimeout(() => {
            logo.style.transform = 'scale(1)';
        }, 200);
    });
}

// ============================================
// Theme Switcher (Future Enhancement)
// ============================================

// You can add theme switching functionality here
// to showcase all 8 themes from your app

const themes = {
    teal: {
        start: 'rgb(20, 184, 166)',
        middle: 'rgb(59, 130, 246)',
        end: 'rgb(96, 165, 250)'
    },
    purple: {
        start: 'rgb(131, 58, 180)',
        middle: 'rgb(88, 86, 214)',
        end: 'rgb(64, 224, 208)'
    },
    red: {
        start: 'rgb(139, 0, 0)',
        middle: 'rgb(178, 34, 34)',
        end: 'rgb(230, 81, 0)'
    },
    // Add other themes as needed
};

function switchTheme(themeName) {
    const theme = themes[themeName];
    if (theme) {
        document.documentElement.style.setProperty('--teal-start', theme.start);
        document.documentElement.style.setProperty('--teal-middle', theme.middle);
        document.documentElement.style.setProperty('--teal-end', theme.end);
    }
}

// ============================================
// Performance Optimization
// ============================================

// Add any performance optimizations here as needed

// ============================================
// Cookie Consent
// ============================================

function initCookieConsent() {
    const cookieBanner = document.getElementById('cookieConsent');
    const acceptButton = document.getElementById('acceptCookies');
    const rejectButton = document.getElementById('rejectCookies');
    
    // Check if user has made a choice
    const cookieChoice = localStorage.getItem('cookieConsent');
    
    if (!cookieChoice) {
        // Show banner after 2 seconds
        setTimeout(() => {
            cookieBanner.classList.remove('hidden');
        }, 2000);
    }
    
    acceptButton.addEventListener('click', () => {
        localStorage.setItem('cookieConsent', 'accepted');
        cookieBanner.classList.add('hidden');
        
        // Initialize analytics after consent
        if (typeof gtag !== 'undefined') {
            gtag('consent', 'update', {
                'analytics_storage': 'granted'
            });
        }
    });
    
    rejectButton.addEventListener('click', () => {
        localStorage.setItem('cookieConsent', 'rejected');
        cookieBanner.classList.add('hidden');
        
        // Clear any existing theme preference
        localStorage.removeItem('theme');
        
        // Deny analytics
        if (typeof gtag !== 'undefined') {
            gtag('consent', 'update', {
                'analytics_storage': 'denied'
            });
        }
    });
}

// ============================================
// Smooth Scroll for Navigation Links
// ============================================

function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            const href = this.getAttribute('href');
            
            // Skip empty or just # links
            if (!href || href === '#') return;
            
            e.preventDefault();
            const target = document.querySelector(href);
            
            if (target) {
                const bannerHeight = document.querySelector('.coming-soon-banner').offsetHeight;
                const targetPosition = target.getBoundingClientRect().top + window.pageYOffset - bannerHeight - 20;
                
                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
            }
        });
    });
}

// ============================================
// Show More Features
// ============================================

function initShowMoreFeatures() {
    const showMoreBtn = document.getElementById('showMoreBtn');
    const hiddenFeatures = document.querySelectorAll('.feature-hidden');
    const showMoreText = showMoreBtn.querySelector('.show-more-text');
    let isExpanded = false;
    
    showMoreBtn.addEventListener('click', () => {
        isExpanded = !isExpanded;
        
        if (isExpanded) {
            // Show features with staggered animation
            hiddenFeatures.forEach((feature, index) => {
                setTimeout(() => {
                    feature.classList.add('feature-visible');
                }, index * 100); // 100ms delay between each feature
            });
            
            // Update button
            showMoreBtn.classList.add('expanded');
            showMoreText.textContent = 'Show Less';
            
        } else {
            // Hide features
            hiddenFeatures.forEach(feature => {
                feature.classList.remove('feature-visible');
            });
            
            // Update button
            showMoreBtn.classList.remove('expanded');
            showMoreText.textContent = 'Show More Features';
            
            // Smooth scroll to features section
            const featuresSection = document.getElementById('features');
            const bannerHeight = document.querySelector('.coming-soon-banner').offsetHeight;
            const targetPosition = featuresSection.getBoundingClientRect().top + window.pageYOffset - bannerHeight - 100;
            
            window.scrollTo({
                top: targetPosition,
                behavior: 'smooth'
            });
        }
    });
}
