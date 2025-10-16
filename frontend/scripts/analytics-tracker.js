/**
 * User Analytics Tracking Script
 * Collects and sends user visit data to the backend analytics API
 */

class UserAnalyticsTracker {
    constructor() {
        this.sessionId = this.generateSessionId();
        this.apiEndpoint = 'https://ocean-hazard-1-6j5g.onrender.com/api/analytics/track-visit';
        this.initialized = false;
    }

    /**
     * Initialize the analytics tracker
     */
    async init() {
        if (this.initialized) return;

        try {
            // Get user location data
            const locationData = await this.getLocationData();

            // Get device and browser information
            const deviceInfo = this.getDeviceInfo();

            // Get user information if logged in
            const userId = this.getUserId();

            // Prepare visit data
            const visitData = {
                ip: await this.getIPAddress(),
                userAgent: navigator.userAgent,
                location: locationData,
                referrer: document.referrer,
                pageUrl: window.location.href,
                sessionId: this.sessionId,
                userId: userId,
                language: navigator.language,
                deviceType: this.getDeviceType(),
                browser: deviceInfo.browser,
                os: deviceInfo.os,
                isBot: this.isBot(),
                timestamp: new Date().toISOString()
            };

            // Send visit data to backend
            await this.sendVisitData(visitData);

            this.initialized = true;

            // Track page changes (for SPA)
            this.trackPageChanges();

        } catch (error) {
            console.warn('Analytics tracking initialization failed:', error);
        }
    }

    /**
     * Generate a unique session ID
     */
    generateSessionId() {
        const existing = localStorage.getItem('ocean_hazard_session_id');
        if (existing) return existing;

        const sessionId = 'session_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
        localStorage.setItem('ocean_hazard_session_id', sessionId);
        return sessionId;
    }

    /**
     * Get user's IP address
     */
    async getIPAddress() {
        try {
            const response = await fetch('https://api.ipify.org?format=json');
            const data = await response.json();
            return data.ip;
        } catch (error) {
            console.warn('Failed to get IP address:', error);
            return 'unknown';
        }
    }

    /**
     * Get location data using browser geolocation API with IP fallback
     */
    async getLocationData() {
        try {
            // Try browser geolocation first (more accurate)
            const browserLocation = await this.getBrowserLocation();
            console.log('Browser location obtained:', browserLocation);

            if (browserLocation.latitude && browserLocation.longitude) {
                // Get additional location data from IP geolocation
                const ipLocation = await this.getIPLocationData();
                const combinedLocation = {
                    ...browserLocation,
                    ...ipLocation
                };
                console.log('Combined location data:', combinedLocation);
                return combinedLocation;
            }
        } catch (error) {
            console.warn('Browser geolocation failed, trying IP geolocation:', error);
        }

        // Fallback to IP geolocation
        try {
            const ipLocation = await this.getIPLocationData();
            console.log('IP location data:', ipLocation);
            return ipLocation;
        } catch (error) {
            console.warn('IP geolocation also failed:', error);
            return {};
        }
    }

    /**
     * Get location using browser geolocation API
     */
    getBrowserLocation() {
        return new Promise((resolve, reject) => {
            if (!navigator.geolocation) {
                reject(new Error('Geolocation not supported'));
                return;
            }

            // Check if user has already denied permission
            if (navigator.permissions) {
                navigator.permissions.query({name: 'geolocation'}).then(permission => {
                    if (permission.state === 'denied') {
                        reject(new Error('Geolocation permission denied'));
                        return;
                    }
                });
            }

            navigator.geolocation.getCurrentPosition(
                (position) => {
                    resolve({
                        latitude: position.coords.latitude,
                        longitude: position.coords.longitude,
                        accuracy: position.coords.accuracy
                    });
                },
                (error) => {
                    console.warn('Browser geolocation error:', error);
                    reject(error);
                },
                {
                    enableHighAccuracy: false, // Changed to false for faster response
                    timeout: 5000, // Reduced timeout
                    maximumAge: 300000 // 5 minutes
                }
            );
        });
    }

    /**
     * Get location data using IP geolocation (fallback)
     */
    async getIPLocationData() {
        try {
            // Using ipapi.co for free geolocation
            const response = await fetch('https://ipapi.co/json/');
            const data = await response.json();

            return {
                country: data.country_name,
                city: data.city,
                region: data.region,
                latitude: data.latitude,
                longitude: data.longitude,
                timezone: data.timezone
            };
        } catch (error) {
            console.warn('Failed to get IP location data:', error);
            return {};
        }
    }

    /**
     * Get device and browser information
     */
    getDeviceInfo() {
        const ua = navigator.userAgent;
        let browser = 'unknown';
        let os = 'unknown';

        // Detect browser
        if (ua.includes('Chrome') && !ua.includes('Edg')) browser = 'Chrome';
        else if (ua.includes('Firefox')) browser = 'Firefox';
        else if (ua.includes('Safari') && !ua.includes('Chrome')) browser = 'Safari';
        else if (ua.includes('Edg')) browser = 'Edge';
        else if (ua.includes('Opera')) browser = 'Opera';

        // Detect OS
        if (ua.includes('Windows')) os = 'Windows';
        else if (ua.includes('Mac')) os = 'macOS';
        else if (ua.includes('Linux')) os = 'Linux';
        else if (ua.includes('Android')) os = 'Android';
        else if (ua.includes('iOS')) os = 'iOS';

        return { browser, os };
    }

    /**
     * Get device type
     */
    getDeviceType() {
        const ua = navigator.userAgent;
        if (ua.includes('Mobile') || ua.includes('Android') || ua.includes('iPhone')) {
            return 'mobile';
        } else if (ua.includes('Tablet') || ua.includes('iPad')) {
            return 'tablet';
        } else {
            return 'desktop';
        }
    }

    /**
     * Check if visitor is a bot
     */
    isBot() {
        const ua = navigator.userAgent.toLowerCase();
        const botPatterns = [
            'bot', 'crawler', 'spider', 'scraper', 'headless',
            'selenium', 'puppeteer', 'chrome-headless'
        ];

        return botPatterns.some(pattern => ua.includes(pattern));
    }

    /**
     * Get user ID if logged in
     */
    getUserId() {
        // Try to get user ID from various sources
        const token = localStorage.getItem('access_token') || sessionStorage.getItem('access_token');
        if (token) {
            try {
                // Decode JWT token to get user ID (simple decode, not secure)
                const payload = JSON.parse(atob(token.split('.')[1]));
                return payload.sub || payload.user_id;
            } catch (error) {
                console.warn('Failed to decode user token:', error);
            }
        }
        return null;
    }

    /**
     * Send visit data to backend
     */
    async sendVisitData(visitData) {
        try {
            const response = await fetch(this.apiEndpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(visitData)
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const result = await response.json();
            console.log('Visit tracked successfully:', result);

        } catch (error) {
            console.warn('Failed to send visit data:', error);
            // Store data locally for retry later
            this.storeFailedVisit(visitData);
        }
    }

    /**
     * Store failed visits for retry
     */
    storeFailedVisit(visitData) {
        const failedVisits = JSON.parse(localStorage.getItem('failed_visits') || '[]');
        failedVisits.push({ ...visitData, timestamp: new Date().toISOString() });
        localStorage.setItem('failed_visits', JSON.stringify(failedVisits));
    }

    /**
     * Retry sending failed visits
     */
    async retryFailedVisits() {
        const failedVisits = JSON.parse(localStorage.getItem('failed_visits') || '[]');
        if (failedVisits.length === 0) return;

        const successfulRetries = [];

        for (const visit of failedVisits) {
            try {
                await this.sendVisitData(visit);
                successfulRetries.push(visit);
            } catch (error) {
                console.warn('Retry failed for visit:', error);
            }
        }

        // Remove successfully sent visits
        const remaining = failedVisits.filter(visit =>
            !successfulRetries.some(retry => retry.timestamp === visit.timestamp)
        );
        localStorage.setItem('failed_visits', JSON.stringify(remaining));
    }

    /**
     * Track page changes for single-page applications
     */
    trackPageChanges() {
        let currentPage = window.location.href;

        // Listen for navigation events
        window.addEventListener('popstate', () => {
            if (window.location.href !== currentPage) {
                currentPage = window.location.href;
                this.trackPageView(currentPage);
            }
        });

        // For frameworks that use pushState/replaceState
        const originalPushState = history.pushState;
        const originalReplaceState = history.replaceState;

        history.pushState = function(state, title, url) {
            originalPushState.apply(this, arguments);
            if (url && url !== currentPage) {
                currentPage = url;
                this.trackPageView(url);
            }
        }.bind(this);

        history.replaceState = function(state, title, url) {
            originalReplaceState.apply(this, arguments);
            if (url && url !== currentPage) {
                currentPage = url;
                this.trackPageView(url);
            }
        }.bind(this);
    }

    /**
     * Track individual page views
     */
    async trackPageView(pageUrl) {
        try {
            const visitData = {
                ip: 'unknown', // Will be determined server-side
                userAgent: navigator.userAgent,
                location: {}, // Will be determined server-side
                referrer: document.referrer,
                pageUrl: pageUrl,
                sessionId: this.sessionId,
                userId: this.getUserId(),
                language: navigator.language,
                deviceType: this.getDeviceType(),
                browser: this.getDeviceInfo().browser,
                os: this.getDeviceInfo().os,
                isBot: this.isBot(),
                timestamp: new Date().toISOString()
            };

            await this.sendVisitData(visitData);
        } catch (error) {
            console.warn('Failed to track page view:', error);
        }
    }
}

// Initialize analytics tracking when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
    const tracker = new UserAnalyticsTracker();
    tracker.init();

    // Retry failed visits every 30 seconds
    setInterval(() => {
        tracker.retryFailedVisits();
    }, 30000);

    // Make tracker available globally for manual tracking if needed
    window.oceanHazardAnalytics = tracker;
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = UserAnalyticsTracker;
}