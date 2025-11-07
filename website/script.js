// ============================================
// RecipeFinder Website JavaScript
// ============================================

document.addEventListener('DOMContentLoaded', () => {
    initThemeToggle();
    initNotifyForm();
    initScrollAnimations();
    initCookieConsent();
    initSmoothScroll();
});

// ============================================
// Theme Toggle
// ============================================

function initThemeToggle() {
    const themeToggle = document.getElementById('themeToggle');
    const themeIcon = themeToggle.querySelector('.theme-icon');
    const root = document.documentElement;
    
    // Check for saved theme preference or default to dark
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme) {
        root.setAttribute('data-theme', savedTheme);
        updateThemeIcon(savedTheme, themeIcon);
    } else {
        // Default to dark mode
        root.setAttribute('data-theme', 'dark');
        updateThemeIcon('dark', themeIcon);
    }
    
    themeToggle.addEventListener('click', () => {
        const currentTheme = root.getAttribute('data-theme');
        const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
        
        root.setAttribute('data-theme', newTheme);
        localStorage.setItem('theme', newTheme);
        updateThemeIcon(newTheme, themeIcon);
    });
}

function updateThemeIcon(theme, iconElement) {
    iconElement.textContent = theme === 'dark' ? '☀️' : '🌙';
}

// ============================================
// Notify Form
// ============================================

function initNotifyForm() {
    const form = document.getElementById('notifyForm');
    const message = document.getElementById('formMessage');

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const email = form.querySelector('input[type="email"]').value;
        
        // Show loading state
        message.textContent = 'Adding you to the list...';
        message.style.color = 'var(--text-secondary)';
        
        // Simulate API call (replace with actual endpoint when ready)
        setTimeout(() => {
            message.textContent = '✓ Success! We\'ll notify you when RecipeFinder launches.';
            message.style.color = 'var(--teal-start)';
            form.reset();
            
            // Clear message after 5 seconds
            setTimeout(() => {
                message.textContent = '';
            }, 5000);
        }, 1000);
        
        // For now, just log it (replace with actual API call)
        console.log('Email submitted:', email);
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
    
    // Check if user has already accepted cookies
    const cookiesAccepted = localStorage.getItem('cookiesAccepted');
    
    if (!cookiesAccepted) {
        // Show banner after 2 seconds
        setTimeout(() => {
            cookieBanner.classList.remove('hidden');
        }, 2000);
    }
    
    acceptButton.addEventListener('click', () => {
        localStorage.setItem('cookiesAccepted', 'true');
        cookieBanner.classList.add('hidden');
        
        // Initialize analytics after consent
        if (typeof gtag !== 'undefined') {
            gtag('consent', 'update', {
                'analytics_storage': 'granted'
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
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}
