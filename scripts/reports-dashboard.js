/**
 * Reports Dashboard - Dynamic Incident Reports Management
 * Role-based access for Admin, Authority, and Rescue Team users
 */

class ReportsManager {
    constructor() {
        this.api = new OceanHazardAPI();
        this.reports = [];
        this.filteredReports = [];
        this.currentUser = null;
        this.currentPage = 1;
        this.reportsPerPage = 10;
        this.filters = {
            search: '',
            status: '',
            hazard_type: '',
            urgency: ''
        };
    }

    async init() {
        try {
            // Check authentication and role access
            await this.checkRoleAccess();
            
            // Setup UI based on user role
            this.setupRoleBasedUI();
            
            // Load reports data
            await this.loadReports();
            
            // Setup event listeners
            this.setupEventListeners();
            
        } catch (error) {
            console.error('❌ Failed to initialize Reports Dashboard:', error);
            this.showError('Failed to initialize dashboard: ' + error.message);
        }
    }

    async checkRoleAccess() {
        const token = localStorage.getItem('oceanGuardToken');
        if (!token) {
            throw new Error('No authentication token found');
        }

        try {
            this.currentUser = await this.api.getCurrentUser();
            
            // Check if user has appropriate role
            const allowedRoles = ['admin', 'authority', 'rescue_team'];
            if (!this.currentUser || !allowedRoles.includes(this.currentUser.role)) {
                throw new Error('Access denied: Insufficient privileges');
            }
            
        } catch (error) {
            throw new Error('Invalid token or insufficient privileges');
        }
    }

    setupRoleBasedUI() {
        const welcomeMessage = document.getElementById('welcome-message');
        const pageTitle = document.getElementById('page-title');
        const pageDescription = document.getElementById('page-description');
        const roleBadge = document.getElementById('role-badge');

        if (welcomeMessage && this.currentUser) {
            welcomeMessage.textContent = `Welcome, ${this.currentUser.full_name || this.currentUser.username}`;
        }

        // Customize UI based on role
        switch (this.currentUser.role) {
            case 'admin':
                pageTitle.textContent = 'Admin - Incident Reports Dashboard';
                pageDescription.textContent = 'Complete oversight and management of all incident reports';
                roleBadge.textContent = '👨‍💼 Administrator';
                roleBadge.style.background = 'rgba(231, 76, 60, 0.3)';
                break;
                
            case 'rescue_team':
                pageTitle.textContent = 'Rescue Team - Incident Response Dashboard';
                pageDescription.textContent = 'Manage and respond to emergency incidents in your area';
                roleBadge.textContent = '🚁 Rescue Team';
                roleBadge.style.background = 'rgba(230, 126, 34, 0.3)';
                break;
                
            case 'authority':
                pageTitle.textContent = 'Authority - Incident Oversight Dashboard';
                pageDescription.textContent = 'Monitor and coordinate incident response activities';
                roleBadge.textContent = '🏛️ Authority';
                roleBadge.style.background = 'rgba(52, 152, 219, 0.3)';
                break;
            
            case 'authority':
                pageTitle.textContent = 'Authority - Incident Reports';
                pageDescription.textContent = 'Monitor and coordinate incident response within your jurisdiction';
                roleBadge.textContent = '🏛️ Authority Personnel';
                roleBadge.style.background = 'rgba(142, 68, 173, 0.3)';
                break;
            
            case 'rescue_team':
                pageTitle.textContent = 'Rescue Team - Active Incidents';
                pageDescription.textContent = 'View assigned incidents and coordinate rescue operations';
                roleBadge.textContent = '🚁 Rescue Team';
                roleBadge.style.background = 'rgba(39, 174, 96, 0.3)';
                break;
        }
    }

    async loadReports() {
        try {
            this.showLoading();
            
            // Use the admin incidents endpoint for authorized users
            const response = await fetch('http://127.0.0.1:9000/api/incidents/', {
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('oceanGuardToken')}`,
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            this.reports = data.incidents || data.items || [];
            this.applyFilters();
            
        } catch (error) {
            console.error('Failed to load reports:', error);
            this.showError('Failed to load incident reports: ' + error.message);
        }
    }

    showLoading() {
        document.getElementById('loading-state').style.display = 'block';
        document.getElementById('error-state').style.display = 'none';
        document.getElementById('empty-state').style.display = 'none';
        document.getElementById('reports-grid').style.display = 'none';
        document.getElementById('pagination').style.display = 'none';
    }

    showError(message) {
        document.getElementById('loading-state').style.display = 'none';
        document.getElementById('error-state').style.display = 'block';
        document.getElementById('empty-state').style.display = 'none';
        document.getElementById('reports-grid').style.display = 'none';
        document.getElementById('pagination').style.display = 'none';
        document.getElementById('error-message').textContent = message;
    }

    showEmpty() {
        document.getElementById('loading-state').style.display = 'none';
        document.getElementById('error-state').style.display = 'none';
        document.getElementById('empty-state').style.display = 'block';
        document.getElementById('reports-grid').style.display = 'none';
        document.getElementById('pagination').style.display = 'none';
    }

    showReports() {
        document.getElementById('loading-state').style.display = 'none';
        document.getElementById('error-state').style.display = 'none';
        document.getElementById('empty-state').style.display = 'none';
        document.getElementById('reports-grid').style.display = 'block';
        document.getElementById('pagination').style.display = 'flex';
    }

    applyFilters() {
        // Get filter values
        this.filters.search = document.getElementById('search-input')?.value.toLowerCase() || '';
        this.filters.status = document.getElementById('status-filter')?.value || '';
        this.filters.hazard_type = document.getElementById('hazard-filter')?.value || '';
        this.filters.urgency = document.getElementById('urgency-filter')?.value || '';

        // Apply filters
        this.filteredReports = this.reports.filter(report => {
            const matchesSearch = !this.filters.search || 
                report.title?.toLowerCase().includes(this.filters.search) ||
                report.location?.toLowerCase().includes(this.filters.search) ||
                report.description?.toLowerCase().includes(this.filters.search) ||
                report.reference_id?.toLowerCase().includes(this.filters.search);

            const matchesStatus = !this.filters.status || report.status === this.filters.status;
            const matchesHazard = !this.filters.hazard_type || report.hazard_type === this.filters.hazard_type;
            const matchesUrgency = !this.filters.urgency || report.urgency === this.filters.urgency;

            return matchesSearch && matchesStatus && matchesHazard && matchesUrgency;
        });

        this.currentPage = 1;
        this.renderReports();
    }

    clearFilters() {
        document.getElementById('search-input').value = '';
        document.getElementById('status-filter').value = '';
        document.getElementById('hazard-filter').value = '';
        document.getElementById('urgency-filter').value = '';
        
        this.filters = { search: '', status: '', hazard_type: '', urgency: '' };
        this.filteredReports = [...this.reports];
        this.currentPage = 1;
        this.renderReports();
    }

    renderReports() {
        if (this.filteredReports.length === 0) {
            this.showEmpty();
            return;
        }

        this.showReports();

        const startIndex = (this.currentPage - 1) * this.reportsPerPage;
        const endIndex = startIndex + this.reportsPerPage;
        const pageReports = this.filteredReports.slice(startIndex, endIndex);

        const reportsGrid = document.getElementById('reports-grid');
        reportsGrid.innerHTML = '';

        pageReports.forEach(report => {
            const reportCard = this.createReportCard(report);
            reportsGrid.appendChild(reportCard);
        });

        this.updatePagination();
    }

    createReportCard(report) {
        const card = document.createElement('div');
        card.className = 'report-card';
        
        const statusClass = this.getStatusClass(report.status);
        const urgencyClass = this.getUrgencyClass(report.urgency);
        
        card.innerHTML = `
            <div class="report-header">
                <h3 class="report-title">${report.title || 'Untitled Report'}</h3>
                <span class="status-badge ${statusClass}">${this.formatStatus(report.status)}</span>
            </div>
            
            <div class="report-meta">
                <div class="meta-item">
                    <i class="fas fa-map-marker-alt"></i>
                    <span>${report.location || 'Location not specified'}</span>
                </div>
                <div class="meta-item">
                    <i class="fas fa-clock"></i>
                    <span>${this.formatDate(report.created_at)}</span>
                </div>
                <div class="meta-item">
                    <i class="fas fa-exclamation-triangle"></i>
                    <span class="${urgencyClass}">Urgency: ${report.urgency || 'Not specified'}</span>
                </div>
                <div class="meta-item">
                    <i class="fas fa-id-card"></i>
                    <span>ID: ${report.reference_id || report.id}</span>
                </div>
                ${report.reporter ? `
                <div class="meta-item">
                    <i class="fas fa-user"></i>
                    <span>Reporter: ${report.reporter.full_name || report.reporter.username}</span>
                </div>
                ` : ''}
            </div>
            
            <div class="report-description">
                <p>${report.description ? report.description.substring(0, 150) + (report.description.length > 150 ? '...' : '') : 'No description provided'}</p>
            </div>
            
            <div class="report-actions">
                <button class="btn-action btn-view" onclick="reportsManager.viewReportDetails('${report.id}')">
                    <i class="fas fa-eye"></i> View Details
                </button>
                ${this.getActionButtons(report)}
            </div>
        `;
        
        return card;
    }

    getActionButtons(report) {
        let buttons = '';
        
        // Role-based action buttons
        switch (this.currentUser.role) {
            case 'admin':
                buttons += `
                    <button class="btn-action btn-verify" onclick="reportsManager.verifyReport('${report.id}')">
                        <i class="fas fa-check"></i> Verify
                    </button>
                    <button class="btn-action btn-assign" onclick="reportsManager.assignReport('${report.id}')">
                        <i class="fas fa-user-plus"></i> Assign
                    </button>
                `;
                break;
                
            case 'authority':
                if (report.status === 'pending') {
                    buttons += `
                        <button class="btn-action btn-verify" onclick="reportsManager.approveReport('${report.id}')">
                            <i class="fas fa-check"></i> Approve
                        </button>
                    `;
                }
                break;
                
            case 'rescue_team':
                // Verify incident (for pending incidents)
                if (report.status === 'pending') {
                    buttons += `
                        <button class="btn-action btn-verify" onclick="reportsManager.verifyIncident('${report.id}')">
                            <i class="fas fa-search"></i> Verify
                        </button>
                    `;
                }
                // Deploy to incident (for verified incidents)
                if (report.status === 'verified' || report.status === 'active') {
                    buttons += `
                        <button class="btn-action btn-deploy" onclick="reportsManager.deployToIncident('${report.id}')">
                            <i class="fas fa-rocket"></i> Deploy
                        </button>
                    `;
                }
                // Resolve incident (for in-progress incidents)
                if (report.status === 'in_progress' || report.status === 'deployed') {
                    buttons += `
                        <button class="btn-action btn-resolve" onclick="reportsManager.resolveIncident('${report.id}')">
                            <i class="fas fa-check-circle"></i> Resolve
                        </button>
                    `;
                }
                break;
        }
        
        return buttons;
    }

    getStatusClass(status) {
        switch (status) {
            case 'pending': return 'status-badge--pending';
            case 'in_progress': case 'active': return 'status-badge--active';
            case 'resolved': return 'status-badge--resolved';
            case 'closed': return 'status-badge--closed';
            default: return 'status-badge--pending';
        }
    }

    getUrgencyClass(urgency) {
        switch (urgency) {
            case 'high': return 'text-danger';
            case 'medium': return 'text-warning';
            case 'low': return 'text-success';
            default: return '';
        }
    }

    formatStatus(status) {
        return status ? status.replace('_', ' ').toUpperCase() : 'UNKNOWN';
    }

    formatDate(dateString) {
        if (!dateString) return 'Unknown date';
        
        try {
            const date = new Date(dateString);
            return date.toLocaleString('en-IN', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        } catch (error) {
            return 'Invalid date';
        }
    }

    updatePagination() {
        const totalPages = Math.ceil(this.filteredReports.length / this.reportsPerPage);
        
        document.getElementById('page-info').textContent = `Page ${this.currentPage} of ${totalPages}`;
        document.getElementById('prev-btn').disabled = this.currentPage <= 1;
        document.getElementById('next-btn').disabled = this.currentPage >= totalPages;
    }

    previousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.renderReports();
        }
    }

    nextPage() {
        const totalPages = Math.ceil(this.filteredReports.length / this.reportsPerPage);
        if (this.currentPage < totalPages) {
            this.currentPage++;
            this.renderReports();
        }
    }

    refreshReports() {
        this.loadReports();
    }

    setupEventListeners() {
        // Real-time search
        const searchInput = document.getElementById('search-input');
        if (searchInput) {
            searchInput.addEventListener('input', () => {
                clearTimeout(this.searchTimeout);
                this.searchTimeout = setTimeout(() => {
                    this.applyFilters();
                }, 300);
            });
        }

        // Logout functionality
        const logoutBtn = document.getElementById('logout-btn');
        if (logoutBtn) {
            logoutBtn.addEventListener('click', (e) => {
                e.preventDefault();
                this.logout();
            });
        }
    }

    // Action methods (placeholders for future implementation)
    viewReportDetails(reportId) {
        const report = this.reports.find(r => r.id == reportId);
        if (report) {
            alert(`Viewing details for report: ${report.title || 'Untitled'}\n\nID: ${report.reference_id || report.id}\nLocation: ${report.location}\nStatus: ${report.status}\n\nDescription: ${report.description}`);
        }
    }

    verifyReport(reportId) {
        alert(`Verify report functionality will be implemented here for report ID: ${reportId}`);
    }

    assignReport(reportId) {
        alert(`Assign report functionality will be implemented here for report ID: ${reportId}`);
    }

    approveReport(reportId) {
        alert(`Approve report functionality will be implemented here for report ID: ${reportId}`);
    }

    async verifyIncident(reportId) {
        try {
            const confirmed = confirm('Are you sure you want to verify this incident? This will mark it as confirmed and ready for deployment.');
            if (!confirmed) return;

            const response = await this.api.verifyIncident(reportId);
            if (response.message) {
                await this.showSuccessMessage(response.message);
                this.loadReports(); // Refresh the reports
            } else {
                throw new Error('Failed to verify incident');
            }
        } catch (error) {
            console.error('Error verifying incident:', error);
            this.showError('Failed to verify incident: ' + error.message);
        }
    }

    async deployToIncident(reportId) {
        try {
            const confirmed = confirm('Are you sure you want to deploy to this incident? This will mark it as in-progress.');
            if (!confirmed) return;

            const response = await this.api.deployResponse(reportId);
            if (response.message) {
                await this.showSuccessMessage(response.message);
                this.loadReports(); // Refresh the reports
            } else {
                throw new Error('Failed to deploy to incident');
            }
        } catch (error) {
            console.error('Error deploying to incident:', error);
            this.showError('Failed to deploy to incident: ' + error.message);
        }
    }

    async resolveIncident(reportId) {
        try {
            const confirmed = confirm('Are you sure you want to resolve this incident? This will mark it as completed.');
            if (!confirmed) return;

            const response = await this.api.resolveIncident(reportId);
            if (response.message) {
                await this.showSuccessMessage(response.message);
                this.loadReports(); // Refresh the reports
            } else {
                throw new Error('Failed to resolve incident');
            }
        } catch (error) {
            console.error('Error resolving incident:', error);
            this.showError('Failed to resolve incident: ' + error.message);
        }
    }

    async showSuccessMessage(message) {
        // Create temporary success message
        const successDiv = document.createElement('div');
        successDiv.className = 'alert alert-success';
        successDiv.style.cssText = 'position: fixed; top: 20px; right: 20px; z-index: 1000; padding: 15px; background: #d4edda; color: #155724; border: 1px solid #c3e6cb; border-radius: 4px;';
        successDiv.textContent = message;
        
        document.body.appendChild(successDiv);
        
        // Remove after 3 seconds
        setTimeout(() => {
            if (successDiv.parentNode) {
                successDiv.parentNode.removeChild(successDiv);
            }
        }, 3000);
    }

    logout() {
        localStorage.removeItem('oceanGuardToken');
        localStorage.removeItem('oceanGuardUser');
        sessionStorage.clear();
        window.location.href = 'index.html';
    }
}

// Initialize reports manager
const reportsManager = new ReportsManager();

// Start the application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    reportsManager.init();
});