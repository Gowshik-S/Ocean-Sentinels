/**
 * My Reports Page - Dynamic functionality
 * Handles fetching and displaying user's reports from the database
 */

class MyReportsManager {
    constructor() {
        this.api = new OceanHazardAPI();
        this.reports = [];
        this.currentUser = null;
    }

    async init() {
        try {
            // Check authentication
            await this.checkAuthentication();
            
            // Load user data and reports
            await this.loadUserData();
            await this.loadReports();
            
        } catch (error) {
            console.error('❌ Failed to initialize My Reports page:', error);
            this.handleAuthError(error);
        }
    }

    async checkAuthentication() {
        // Check for token in localStorage first
        let token = localStorage.getItem('oceanGuardToken');
        let user = JSON.parse(localStorage.getItem('oceanGuardUser') || 'null');
        
        // Fallback to sessionStorage if not found in localStorage
        if (!token || !user) {
            user = JSON.parse(sessionStorage.getItem('oceanGuardUser') || 'null');
            
            if (user) {
                // If we have user data but no token, create a mock token for compatibility
                if (!token) {
                    token = `mock-token-${user.role || 'public'}-${Date.now()}`;
                    localStorage.setItem('oceanGuardToken', token);
                    localStorage.setItem('oceanGuardUser', JSON.stringify(user));
                }
            }
        }
        
        if (!token || !user) {
            throw new Error('No authentication found. Please login first.');
        }

        // For mock tokens (demo users), just set the user directly
        if (token.startsWith('mock-token-')) {
            this.currentUser = {
                id: user.id || 1,
                username: user.email || 'demo_user',
                full_name: user.name || `${user.first_name || 'Demo'} ${user.last_name || 'User'}`,
                role: user.role || 'public'
            };
            return;
        }

        // For real tokens, verify with the API
        try {
            this.currentUser = await this.api.getCurrentUser();
        } catch (error) {
            throw new Error('Invalid or expired token');
        }
    }

    async loadUserData() {
        if (this.currentUser) {
            const welcomeMessage = document.getElementById('welcome-message');
            if (welcomeMessage) {
                welcomeMessage.textContent = `Welcome, ${this.currentUser.full_name || this.currentUser.username}`;
            }
        }
    }

    async loadReports() {
        try {
            const loadingMessage = document.getElementById('loading-message');
            const noReportsMessage = document.getElementById('no-reports-message');
            const reportsContainer = document.getElementById('reports-container');

            // Show loading
            loadingMessage.style.display = 'block';
            noReportsMessage.style.display = 'none';

            // Check if user has a valid authentication token
            const token = localStorage.getItem('oceanGuardToken');
            if (!token || token.startsWith('mock-token-')) {
                console.warn('🔐 No valid authentication token found');
                // For demo purposes, show mock data
                this.showMockReports();
                return;
            }

            // Fetch user's reports
            console.log('📡 Fetching reports from API...');
            const response = await this.api.getMyReports({
                page: 1,
                size: 100  // Get all user reports
            });

            console.log('✅ Reports API response:', response);
            this.reports = response.incidents || [];

            // Hide loading
            loadingMessage.style.display = 'none';

            if (this.reports.length === 0) {
                noReportsMessage.style.display = 'block';
            } else {
                this.renderReports();
            }

            // Update statistics
            this.updateStats();

        } catch (error) {
            console.error('❌ Failed to load reports:', error);
            
            // Hide loading
            const loadingMessage = document.getElementById('loading-message');
            if (loadingMessage) loadingMessage.style.display = 'none';
            
            // Check if it's an authentication error
            if (error.message.includes('401') || error.message.includes('Not authenticated')) {
                this.handleAuthError(error);
                return;
            }
            
            // For other errors, show mock data as fallback
            console.warn('🔄 Falling back to mock data due to API error');
            this.showMockReports();
        }
    }

    renderReports() {
        const reportsContainer = document.getElementById('reports-container');
        
        // Clear existing content except loading and no-reports messages
        const existingCards = reportsContainer.querySelectorAll('.report-card');
        existingCards.forEach(card => card.remove());

        // Create report cards
        this.reports.forEach(report => {
            const reportCard = this.createReportCard(report);
            reportsContainer.appendChild(reportCard);
        });
    }

    createReportCard(report) {
        const card = document.createElement('div');
        card.className = 'report-card';
        card.setAttribute('data-report-id', report.id);

        const statusClass = this.getStatusClass(report.status);
        const statusText = this.getStatusText(report.status);
        const hazardTitle = this.getHazardTitle(report.hazard_type);
        const urgencyIcon = this.getUrgencyIcon(report.urgency);
        const formattedDate = this.formatDate(report.created_at);

        card.innerHTML = `
            <div class="card-header">
                <h3>${urgencyIcon} ${hazardTitle}</h3>
                <span class="status-badge ${statusClass}">${statusText}</span>
            </div>
            <div class="card-body">
                <p class="location">
                    <i class="fas fa-map-marker-alt"></i> 
                    ${report.location}
                </p>
                <p class="timestamp">
                    <i class="fas fa-clock"></i> 
                    You reported this on: ${formattedDate}
                </p>
                <p class="reference-id">
                    <i class="fas fa-hashtag"></i> 
                    Reference: ${report.reference_id}
                </p>
                ${report.description ? `
                    <p class="description">
                        <i class="fas fa-info-circle"></i> 
                        ${report.description.substring(0, 100)}${report.description.length > 100 ? '...' : ''}
                    </p>
                ` : ''}
            </div>
            <div class="card-actions">
                <button class="btn btn--secondary" onclick="myReportsManager.viewReportDetails('${report.reference_id}')">
                    View Details
                </button>
                ${this.canUpdateReport(report) ? `
                    <button class="btn btn--outline" onclick="myReportsManager.editReport('${report.reference_id}')">
                        Edit
                    </button>
                ` : ''}
            </div>
        `;

        return card;
    }

    getStatusClass(status) {
        const statusMap = {
            'pending': 'status-badge--pending',
            'verified': 'status-badge--verified',
            'in_progress': 'status-badge--active',
            'resolved': 'status-badge--resolved',
            'false_alarm': 'status-badge--false-alarm'
        };
        return statusMap[status] || 'status-badge--pending';
    }

    getStatusText(status) {
        const statusMap = {
            'pending': 'Pending Review',
            'verified': 'Verified',
            'in_progress': 'In Progress',
            'resolved': 'Resolved',
            'false_alarm': 'False Alarm'
        };
        return statusMap[status] || 'Unknown';
    }

    getHazardTitle(hazardType) {
        const hazardMap = {
            'high-waves': 'High Wave Warning',
            'flooding': 'Coastal Flooding',
            'tsunami': 'Tsunami Alert',
            'lost-vessel': 'Lost Vessel',
            'debris': 'Marine Debris',
            'oil-spill': 'Oil Spill',
            'other': 'Other Hazard'
        };
        return hazardMap[hazardType] || 'Unknown Hazard';
    }

    getUrgencyIcon(urgency) {
        const urgencyMap = {
            'low': '<i class="fas fa-info-circle text-blue"></i>',
            'medium': '<i class="fas fa-exclamation-triangle text-yellow"></i>',
            'high': '<i class="fas fa-exclamation-circle text-orange"></i>',
            'critical': '<i class="fas fa-exclamation text-red"></i>'
        };
        return urgencyMap[urgency] || '';
    }

    formatDate(dateString) {
        const date = new Date(dateString);
        const options = {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
        };
        return date.toLocaleDateString('en-US', options);
    }

    canUpdateReport(report) {
        // Users can edit reports that are still pending
        return report.status === 'pending';
    }

    updateStats() {
        const totalReports = this.reports.length;
        const resolvedReports = this.reports.filter(r => r.status === 'resolved').length;
        const activeReports = this.reports.filter(r => 
            ['pending', 'verified', 'in_progress'].includes(r.status)
        ).length;

        // Update DOM elements
        const totalElement = document.getElementById('total-reports');
        const resolvedElement = document.getElementById('resolved-reports');
        const activeElement = document.getElementById('active-reports');

        if (totalElement) totalElement.textContent = totalReports;
        if (resolvedElement) resolvedElement.textContent = resolvedReports;
        if (activeElement) activeElement.textContent = activeReports;

        // Animate the numbers
        this.animateCounter(totalElement, totalReports);
        this.animateCounter(resolvedElement, resolvedReports);
        this.animateCounter(activeElement, activeReports);
    }

    animateCounter(element, targetValue) {
        if (!element) return;
        
        const startValue = 0;
        const duration = 1000;
        const startTime = performance.now();

        function updateCounter(currentTime) {
            const elapsed = currentTime - startTime;
            const progress = Math.min(elapsed / duration, 1);
            
            const currentValue = Math.floor(startValue + (targetValue - startValue) * progress);
            element.textContent = currentValue;

            if (progress < 1) {
                requestAnimationFrame(updateCounter);
            }
        }

        requestAnimationFrame(updateCounter);
    }

    async viewReportDetails(referenceId) {
        try {
            // Find the report
            const report = this.reports.find(r => r.reference_id === referenceId);
            if (!report) {
                this.showError('Report not found');
                return;
            }

            // Create and show modal with report details
            this.showReportModal(report);

        } catch (error) {
            console.error('❌ Failed to view report details:', error);
            this.showError('Failed to load report details');
        }
    }

    showReportModal(report) {
        // Create modal overlay
        const modalOverlay = document.createElement('div');
        modalOverlay.className = 'modal-overlay';
        modalOverlay.innerHTML = `
            <div class="modal-content">
                <div class="modal-header">
                    <h2>${this.getHazardTitle(report.hazard_type)}</h2>
                    <button class="modal-close" onclick="this.closest('.modal-overlay').remove()">
                        <i class="fas fa-times"></i>
                    </button>
                </div>
                <div class="modal-body">
                    <div class="report-details">
                        <div class="detail-row">
                            <span class="label">Reference ID:</span>
                            <span class="value">${report.reference_id}</span>
                        </div>
                        <div class="detail-row">
                            <span class="label">Status:</span>
                            <span class="value">
                                <span class="status-badge ${this.getStatusClass(report.status)}">
                                    ${this.getStatusText(report.status)}
                                </span>
                            </span>
                        </div>
                        <div class="detail-row">
                            <span class="label">Location:</span>
                            <span class="value">${report.location}</span>
                        </div>
                        <div class="detail-row">
                            <span class="label">Urgency:</span>
                            <span class="value">${report.urgency.toUpperCase()}</span>
                        </div>
                        <div class="detail-row">
                            <span class="label">Reported On:</span>
                            <span class="value">${this.formatDate(report.created_at)}</span>
                        </div>
                        ${report.description ? `
                            <div class="detail-row full-width">
                                <span class="label">Description:</span>
                                <span class="value description-text">${report.description}</span>
                            </div>
                        ` : ''}
                        ${report.contact_info ? `
                            <div class="detail-row">
                                <span class="label">Contact Info:</span>
                                <span class="value">${report.contact_info}</span>
                            </div>
                        ` : ''}
                        ${report.latitude && report.longitude ? `
                            <div class="detail-row">
                                <span class="label">Coordinates:</span>
                                <span class="value">${report.latitude}, ${report.longitude}</span>
                            </div>
                        ` : ''}
                    </div>
                </div>
                <div class="modal-footer">
                    <button class="btn btn--secondary" onclick="this.closest('.modal-overlay').remove()">
                        Close
                    </button>
                </div>
            </div>
        `;

        // Add to body
        document.body.appendChild(modalOverlay);

        // Close on overlay click
        modalOverlay.addEventListener('click', (e) => {
            if (e.target === modalOverlay) {
                modalOverlay.remove();
            }
        });
    }

    editReport(referenceId) {
        // For now, redirect to main page with edit mode
        // In a full implementation, you might have a dedicated edit page
        alert(`Edit functionality for report ${referenceId} would be implemented here.\nFor now, please contact support if you need to modify your report.`);
    }

    showError(message) {
        // Create error notification
        const errorDiv = document.createElement('div');
        errorDiv.className = 'error-notification';
        errorDiv.innerHTML = `
            <i class="fas fa-exclamation-circle"></i>
            <span>${message}</span>
            <button onclick="this.parentElement.remove()">
                <i class="fas fa-times"></i>
            </button>
        `;

        document.body.appendChild(errorDiv);

        // Auto remove after 5 seconds
        setTimeout(() => {
            if (errorDiv.parentElement) {
                errorDiv.remove();
            }
        }, 5000);
    }

    handleAuthError(error) {
        console.error('Authentication error:', error);
        
        // Clear stored auth data
        localStorage.removeItem('oceanGuardToken');
        localStorage.removeItem('oceanGuardUser');
        
        // Redirect to main page
        alert('Your session has expired. Please log in again.');
        window.location.href = 'index.html';
    }

    // Handle logout
    async logout() {
        try {
            await this.api.logout();
            window.location.href = 'index.html';
        } catch (error) {
            console.error('Logout error:', error);
            // Force logout anyway
            localStorage.removeItem('oceanGuardToken');
            localStorage.removeItem('oceanGuardUser');
            window.location.href = 'index.html';
        }
    }
}

// Initialize the reports manager
const myReportsManager = new MyReportsManager();

// DOM Content Loaded
document.addEventListener('DOMContentLoaded', () => {
    myReportsManager.init();

    // Setup logout button
    const logoutBtn = document.getElementById('logout-btn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', (e) => {
            e.preventDefault();
            myReportsManager.logout();
        });
    }
});