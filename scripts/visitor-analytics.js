/**
 * Visitor Analytics - Ocean Guard
 * Comprehensive visitor tracking and analytics dashboard
 */

class VisitorAnalytics {
    constructor() {
        this.api = new OceanHazardAPI();
        this.currentUser = null;
        this.charts = {};
        this.filters = {
            period: 30,
            country: '',
            device: ''
        };
    }

    async init() {
        try {
            // Check authentication and admin access
            await this.checkAdminAccess();

            // Load initial data
            await this.loadData();

            // Setup event listeners
            this.setupEventListeners();

        } catch (error) {
            console.error('❌ Failed to initialize visitor analytics:', error);
            this.showAccessDenied();
        }
    }

    async checkAdminAccess() {
        console.log('🔍 Checking admin access...');

        const token = localStorage.getItem('oceanGuardToken');
        console.log('Token found:', token ? 'Yes' : 'No');

        if (!token) {
            console.log('❌ No authentication token found');
            throw new Error('No authentication token found');
        }

        try {
            console.log('🔄 Fetching current user...');
            this.currentUser = await this.api.getCurrentUser();
            console.log('✅ Current user retrieved:', this.currentUser);
            console.log('User role type:', typeof this.currentUser.role, 'Value:', this.currentUser.role);

            // Check if user has admin role - database uses UPPERCASE, backend might return either
            const userRole = this.currentUser.role;
            const isAdmin = userRole === 'ADMIN' || userRole === 'admin' || userRole === 'Admin';

            if (!isAdmin) {
                console.log('❌ User is not an admin');
                throw new Error('Admin access required');
            }

            console.log('✅ Admin access confirmed');

        } catch (error) {
            console.error('❌ Admin access check failed:', error);
            throw error;
        }
    }

    showAccessDenied() {
        document.getElementById('access-denied').style.display = 'block';
        document.getElementById('visitor-content').style.display = 'none';
    }

    async loadData() {
        try {
            console.log('📊 Loading visitor analytics data...');

            // Show loading state
            this.showLoading();

            // Load all data in parallel
            await Promise.all([
                this.loadAnalyticsStats(),
                this.loadVisitsSummary(),
                this.loadRecentVisits(),
                this.loadCountryOptions()
            ]);

        } catch (error) {
            console.error('❌ Failed to load analytics data:', error);
            this.showError('Failed to load analytics data: ' + error.message);
        } finally {
            this.hideLoading();
        }
    }

    showLoading() {
        // Update table to show loading
        document.getElementById('visits-table-body').innerHTML =
            '<tr><td colspan="8" class="text-center">Loading visitor details...</td></tr>';
    }

    hideLoading() {
        // Loading is complete
    }

    showError(message) {
        const errorDiv = document.createElement('div');
        errorDiv.className = 'error-message';
        errorDiv.innerHTML = `<i class="fas fa-exclamation-triangle"></i> ${message}`;
        document.querySelector('.visitor-container').insertBefore(errorDiv, document.querySelector('.visitor-header').nextSibling);

        // Remove error after 5 seconds
        setTimeout(() => {
            if (errorDiv.parentNode) {
                errorDiv.parentNode.removeChild(errorDiv);
            }
        }, 5000);
    }

    async loadAnalyticsStats() {
        try {
            const response = await fetch(`${this.api.baseURL}/analytics/visits/stats`, {
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('oceanGuardToken')}`,
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const stats = await response.json();

            // Update stats cards
            document.getElementById('today-visits').textContent = stats.today_visits.toLocaleString();
            document.getElementById('week-visits').textContent = stats.week_visits.toLocaleString();
            document.getElementById('month-visits').textContent = stats.month_visits.toLocaleString();
            document.getElementById('total-visits').textContent = stats.total_visits.toLocaleString();
            document.getElementById('unique-visitors').textContent = stats.unique_visitors.toLocaleString();
            document.getElementById('online-users').textContent = stats.online_users.toLocaleString();

        } catch (error) {
            console.error('❌ Failed to load analytics stats:', error);
            // Set defaults
            document.getElementById('today-visits').textContent = '0';
            document.getElementById('week-visits').textContent = '0';
            document.getElementById('month-visits').textContent = '0';
            document.getElementById('total-visits').textContent = '0';
            document.getElementById('unique-visitors').textContent = '0';
            document.getElementById('online-users').textContent = '0';
        }
    }

    async loadVisitsSummary() {
        try {
            const response = await fetch(`${this.api.baseURL}/analytics/visits/summary?days=${this.filters.period}`, {
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('oceanGuardToken')}`,
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const summary = await response.json();
            this.renderAnalyticsCharts(summary);

        } catch (error) {
            console.error('❌ Failed to load visits summary:', error);
        }
    }

    renderAnalyticsCharts(summary) {
        // Country chart
        const countryCtx = document.getElementById('countryChart').getContext('2d');
        if (this.charts.countryChart) {
            this.charts.countryChart.destroy();
        }
        this.charts.countryChart = new Chart(countryCtx, {
            type: 'pie',
            data: {
                labels: Object.keys(summary.visits_by_country),
                datasets: [{
                    data: Object.values(summary.visits_by_country),
                    backgroundColor: [
                        '#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0',
                        '#9966FF', '#FF9F40', '#FF6384', '#C9CBCF'
                    ]
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        });

        // Device chart
        const deviceCtx = document.getElementById('deviceChart').getContext('2d');
        if (this.charts.deviceChart) {
            this.charts.deviceChart.destroy();
        }
        this.charts.deviceChart = new Chart(deviceCtx, {
            type: 'doughnut',
            data: {
                labels: Object.keys(summary.visits_by_device),
                datasets: [{
                    data: Object.values(summary.visits_by_device),
                    backgroundColor: ['#FF6384', '#36A2EB', '#FFCE56']
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        });

        // Daily visits chart
        const dailyCtx = document.getElementById('dailyVisitsChart').getContext('2d');
        if (this.charts.dailyVisitsChart) {
            this.charts.dailyVisitsChart.destroy();
        }
        const dailyLabels = summary.daily_visits.map(day => {
            const date = new Date(day.date);
            return date.toLocaleDateString();
        });
        const dailyData = summary.daily_visits.map(day => day.visits);

        this.charts.dailyVisitsChart = new Chart(dailyCtx, {
            type: 'line',
            data: {
                labels: dailyLabels,
                datasets: [{
                    label: 'Daily Visits',
                    data: dailyData,
                    borderColor: '#005A9C',
                    backgroundColor: 'rgba(0, 90, 156, 0.1)',
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });

        // Top pages chart (mock data for now - would need backend endpoint)
        const pagesCtx = document.getElementById('topPagesChart').getContext('2d');
        if (this.charts.topPagesChart) {
            this.charts.topPagesChart.destroy();
        }
        this.charts.topPagesChart = new Chart(pagesCtx, {
            type: 'bar',
            data: {
                labels: ['Home', 'Analytics', 'Reports', 'My Reports', 'Admin'],
                datasets: [{
                    label: 'Page Views',
                    data: [150, 89, 67, 45, 23],
                    backgroundColor: '#005A9C'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }

    async loadRecentVisits() {
        try {
            const response = await fetch(`${this.api.baseURL}/analytics/visits/details?limit=100&days=${this.filters.period}`, {
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('oceanGuardToken')}`,
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            this.renderRecentVisits(data.visits);

        } catch (error) {
            console.error('❌ Failed to load recent visits:', error);
            document.getElementById('visits-table-body').innerHTML =
                '<tr><td colspan="8" class="text-center">Failed to load visitor details</td></tr>';
        }
    }

    renderRecentVisits(visits) {
        const tbody = document.getElementById('visits-table-body');

        if (!visits || visits.length === 0) {
            tbody.innerHTML = '<tr><td colspan="8" class="text-center">No visitor data found</td></tr>';
            return;
        }

        tbody.innerHTML = visits.map(visit => {
            const timestamp = new Date(visit.created_at).toLocaleString();
            const location = [visit.city, visit.country].filter(Boolean).join(', ') || 'Unknown';
            const coordinates = visit.latitude && visit.longitude ?
                `${visit.latitude.toFixed(4)}, ${visit.longitude.toFixed(4)}` : 'N/A';
            const device = visit.device_type || 'Unknown';
            const browser = visit.browser || 'Unknown';
            const page = visit.page_url ? new URL(visit.page_url).pathname : '/';
            const referrer = visit.referrer ? new URL(visit.referrer).hostname : 'Direct';

            return `
                <tr>
                    <td>${timestamp}</td>
                    <td>${visit.ip_address}</td>
                    <td>${location}</td>
                    <td>${coordinates}</td>
                    <td>${device}</td>
                    <td>${browser}</td>
                    <td>${page}</td>
                    <td>${referrer}</td>
                </tr>
            `;
        }).join('');
    }

    async loadCountryOptions() {
        try {
            const response = await fetch(`${this.api.baseURL}/analytics/visits/summary?days=90`, {
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('oceanGuardToken')}`,
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const summary = await response.json();
            const countries = Object.keys(summary.visits_by_country);

            const countryFilter = document.getElementById('country-filter');
            countries.forEach(country => {
                const option = document.createElement('option');
                option.value = country;
                option.textContent = country;
                countryFilter.appendChild(option);
            });

        } catch (error) {
            console.error('❌ Failed to load country options:', error);
        }
    }

    setupEventListeners() {
        // Period filter
        document.getElementById('period-select').addEventListener('change', (e) => {
            this.filters.period = parseInt(e.target.value);
            this.loadData();
        });

        // Country filter
        document.getElementById('country-filter').addEventListener('change', (e) => {
            this.filters.country = e.target.value;
            this.applyFilters();
        });

        // Device filter
        document.getElementById('device-filter').addEventListener('change', (e) => {
            this.filters.device = e.target.value;
            this.applyFilters();
        });

        // Chart period controls
        document.getElementById('country-chart-period').addEventListener('change', () => this.loadVisitsSummary());
        document.getElementById('device-chart-period').addEventListener('change', () => this.loadVisitsSummary());
        document.getElementById('daily-chart-period').addEventListener('change', () => this.loadVisitsSummary());
        document.getElementById('pages-chart-period').addEventListener('change', () => this.loadVisitsSummary());
    }

    applyFilters() {
        // For now, just reload data (filters would need backend support)
        this.loadRecentVisits();
    }

    async refreshData() {
        await this.loadData();
        this.showSuccess('Data refreshed successfully!');
    }

    showSuccess(message) {
        const successDiv = document.createElement('div');
        successDiv.className = 'error-message';
        successDiv.style.background = '#d4edda';
        successDiv.style.color = '#155724';
        successDiv.style.borderColor = '#c3e6cb';
        successDiv.innerHTML = `<i class="fas fa-check-circle"></i> ${message}`;

        document.querySelector('.visitor-container').insertBefore(successDiv, document.querySelector('.visitor-header').nextSibling);

        // Remove success message after 3 seconds
        setTimeout(() => {
            if (successDiv.parentNode) {
                successDiv.parentNode.removeChild(successDiv);
            }
        }, 3000);
    }
}

// Initialize visitor analytics
const visitorAnalytics = new VisitorAnalytics();

// Start the application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    visitorAnalytics.init();
});