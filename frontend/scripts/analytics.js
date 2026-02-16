/**
 * Ocean Sentinels Public Analytics Dashboard
 * Dynamic data fetching from backend API with Chart.js visualizations
 * Public access version - limited data for general public
 */

// Global variables for charts
let incidentsTypeChart, incidentsTimelineChart, statusDistributionChart;
let analyticsData = null;

// Initialize analytics when page loads
document.addEventListener('DOMContentLoaded', function () {
    console.log('🌊 Analytics Dashboard Initializing...');
    displayLoginStatus();
    initializeAnalytics();
});

/**
 * Display login status in the header or somewhere visible
 */
function displayLoginStatus() {
    const token = localStorage.getItem('oceanGuardToken');
    const user = localStorage.getItem('oceanGuardUser');

    console.log('🔍 Checking login status...');
    console.log('Token exists:', !!token);
    console.log('User data:', user);

    if (token && user) {
        try {
            const userData = JSON.parse(user);
            console.log('✅ User is logged in:', userData);
            console.log('User role:', userData.role);
        } catch (e) {
            console.log('User data exists but is not JSON:', user);
        }
    } else {
        console.log('⚠️ User is not logged in');
    }
}

/**
 * Initialize the analytics dashboard
 */
async function initializeAnalytics() {
    try {
        showLoading();
        await loadAnalytics();
        hideLoading();
        updateLastUpdatedTime();
    } catch (error) {
        console.error('❌ Failed to initialize analytics:', error);
        showError('Failed to load analytics dashboard');
    }
}

/**
 * Load analytics data from API with fallback to mock data
 */
async function loadAnalytics() {
    try {
        console.log('📊 Loading analytics data from database...');

        // Fetch real data from backend
        let dashboardData, timelineData;

        try {
            // Fetch dashboard analytics from real backend API
            console.log('🔄 Fetching dashboard analytics...');
            const dashboardResponse = await fetch('https://ocean-sentinels.onrender.com/api/analytics/public/dashboard', {
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            if (dashboardResponse.ok) {
                dashboardData = await dashboardResponse.json();
                console.log('✅ Real dashboard data loaded:', dashboardData);
            } else {
                throw new Error(`Dashboard API failed: ${dashboardResponse.status}`);
            }

            // Fetch timeline data from real backend API
            console.log('🔄 Fetching timeline analytics...');
            const timelineResponse = await fetch('https://ocean-sentinels.onrender.com/api/analytics/public/timeline?days=30', {
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            if (timelineResponse.ok) {
                timelineData = await timelineResponse.json();
                console.log('✅ Real timeline data loaded:', timelineData);
            } else {
                throw new Error(`Timeline API failed: ${timelineResponse.status}`);
            }

        } catch (apiError) {
            console.error('❌ Backend API error:', apiError.message);
            throw new Error(`Failed to fetch analytics data: ${apiError.message}`);
        }

        // Store analytics data globally
        analyticsData = {
            dashboard: dashboardData,
            timeline: timelineData
        };

        // Update UI - show content FIRST so charts can measure canvas dimensions
        updateOverviewCards(dashboardData);
        showContent();

        // Create charts AFTER content is visible (Chart.js needs rendered dimensions)
        // Use requestAnimationFrame to ensure the browser has painted the container
        requestAnimationFrame(() => {
            createCharts(dashboardData, timelineData);
        });

        loadRecentActivity();
        loadIncidentsTable();

    } catch (error) {
        console.error('❌ Error loading analytics:', error);
        throw error;
    }
}

/**
 * Update overview statistics cards
 */
function updateOverviewCards(data) {
    try {
        // Update top overview cards (with null checks for page compatibility)
        const totalEl = document.getElementById('total-incidents');
        const activeEl = document.getElementById('active-incidents');
        const resolvedEl = document.getElementById('resolved-incidents');
        const avgResponseEl = document.getElementById('avg-response-time');
        const safetyScoreEl = document.getElementById('safety-score');

        if (totalEl) totalEl.textContent = data.total_incidents || 0;
        if (activeEl) activeEl.textContent = data.active_incidents || 0;
        if (resolvedEl) resolvedEl.textContent = data.resolved_incidents || 0;

        // Calculate average response time (mock data for now)
        const avgResponseHours = Math.round((data.resolved_incidents || 0) * 2.5);
        if (avgResponseEl) avgResponseEl.textContent = `${avgResponseHours}h`;

        // Update safety score if element exists
        if (safetyScoreEl) {
            const safetyScore = data.total_incidents > 0
                ? Math.max(0, 100 - Math.round((data.active_incidents || 0) / data.total_incidents * 100))
                : 100;
            safetyScoreEl.textContent = safetyScore;
        }

        // Update KPI cards with the same data
        const kpiActiveElement = document.getElementById('kpi-active-incidents');
        const kpiTotalElement = document.getElementById('kpi-total-reports');
        const kpiResponseElement = document.getElementById('kpi-response-time');
        const kpiResolvedElement = document.getElementById('kpi-resolved-incidents');

        if (kpiActiveElement) kpiActiveElement.textContent = data.active_incidents || 0;
        if (kpiTotalElement) kpiTotalElement.textContent = data.total_incidents || 0;
        if (kpiResponseElement) {
            const responseTime = avgResponseHours > 0 ? `${avgResponseHours}h` : '0h';
            kpiResponseElement.textContent = responseTime;
        }
        if (kpiResolvedElement) kpiResolvedElement.textContent = data.resolved_incidents || 0;

        console.log('✅ Overview cards and KPI cards updated');
    } catch (error) {
        console.error('❌ Error updating overview cards:', error);
    }
}

/**
 * Create all charts
 */
function createCharts(dashboardData, timelineData) {
    try {
        createIncidentsTypeChart(dashboardData);
        createTimelineChart(timelineData);
        createStatusDistributionChart(dashboardData);
        console.log('✅ All charts created');
    } catch (error) {
        console.error('❌ Error creating charts:', error);
    }
}

/**
 * Create incidents by type chart
 */
function createIncidentsTypeChart(data) {
    const ctx = document.getElementById('incidentsTypeChart') || document.getElementById('incidents-type-chart');
    if (!ctx) return;

    if (incidentsTypeChart) {
        incidentsTypeChart.destroy();
    }

    const incidentTypes = data.incidents_by_type || {};

    // Convert enum keys to readable labels
    const labels = Object.keys(incidentTypes).map(convertHazardTypeToLabel);
    const values = Object.values(incidentTypes);

    incidentsTypeChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: labels.length ? labels : ['No Data'],
            datasets: [{
                data: values.length ? values : [1],
                backgroundColor: [
                    '#FF6384',
                    '#36A2EB',
                    '#FFCE56',
                    '#4BC0C0',
                    '#9966FF',
                    '#FF9F40'
                ],
                borderWidth: 2,
                borderColor: '#fff'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: {
                        padding: 20,
                        usePointStyle: true
                    }
                }
            }
        }
    });
}

/**
 * Create timeline chart
 */
function createTimelineChart(timelineData) {
    const ctx = document.getElementById('incidentsTimelineChart') || document.getElementById('incidents-timeline-chart');
    if (!ctx) return;

    if (incidentsTimelineChart) {
        incidentsTimelineChart.destroy();
    }

    // Process timeline data
    const labels = [];
    const data = [];

    if (timelineData && timelineData.length > 0) {
        timelineData.forEach(item => {
            labels.push(new Date(item.date).toLocaleDateString());
            data.push(item.count);
        });
    } else {
        // Default empty data for last 7 days
        for (let i = 6; i >= 0; i--) {
            const date = new Date();
            date.setDate(date.getDate() - i);
            labels.push(date.toLocaleDateString());
            data.push(0);
        }
    }

    incidentsTimelineChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: 'Incidents',
                data: data,
                borderColor: '#007bff',
                backgroundColor: 'rgba(0, 123, 255, 0.1)',
                borderWidth: 3,
                fill: true,
                tension: 0.4,
                pointBackgroundColor: '#007bff',
                pointBorderColor: '#fff',
                pointBorderWidth: 2,
                pointRadius: 6
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        stepSize: 1
                    }
                }
            }
        }
    });
}

/**
 * Create status distribution chart
 */
function createStatusDistributionChart(data) {
    const ctx = document.getElementById('statusDistributionChart') || document.getElementById('status-distribution-chart');
    if (!ctx) return;

    if (statusDistributionChart) {
        statusDistributionChart.destroy();
    }

    const statusData = {
        'Pending': data.active_incidents || 0,
        'Resolved': data.resolved_incidents || 0,
        'Verified': Math.floor((data.resolved_incidents || 0) * 0.8) // Mock verified count
    };

    statusDistributionChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: Object.keys(statusData),
            datasets: [{
                data: Object.values(statusData),
                backgroundColor: [
                    '#ffc107',
                    '#28a745',
                    '#007bff'
                ],
                borderWidth: 1,
                borderColor: '#fff'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        stepSize: 1
                    }
                }
            }
        }
    });
}

/**
 * Load recent activity
 */
async function loadRecentActivity() {
    try {
        const activityContainer = document.getElementById('recent-activity');
        if (!activityContainer) return;

        console.log('🔄 Loading recent activity from database...');

        // Try to fetch recent incidents from API
        let activities = [];

        try {
            // Get recent incidents (first check if user is logged in for auth)
            const token = localStorage.getItem('oceanGuardToken');
            const headers = {
                'Content-Type': 'application/json'
            };

            if (token) {
                headers['Authorization'] = `Bearer ${token}`;
            }

            const response = await fetch('https://ocean-sentinels.onrender.com/api/incidents/?page=1&size=5', {
                headers: headers
            });

            if (response.ok) {
                const incidentsData = await response.json();
                console.log('✅ Recent incidents loaded:', incidentsData);

                // Transform incidents to activity format
                activities = incidentsData.incidents?.slice(0, 3).map(incident => {
                    const timeAgo = getTimeAgo(new Date(incident.created_at));
                    const hazardType = convertHazardTypeToLabel(incident.hazard_type);
                    let type, text, icon;

                    switch (incident.status) {
                        case 'PENDING':
                            type = 'pending';
                            text = `New ${hazardType} reported in ${incident.location}`;
                            icon = 'fas fa-exclamation-circle';
                            break;
                        case 'RESOLVED':
                            type = 'resolved';
                            text = `${hazardType} incident resolved in ${incident.location}`;
                            icon = 'fas fa-check-circle';
                            break;
                        case 'VERIFIED':
                            type = 'verified';
                            text = `${hazardType} incident verified in ${incident.location}`;
                            icon = 'fas fa-clipboard-check';
                            break;
                        case 'IN_PROGRESS':
                            type = 'in-progress';
                            text = `Response team deployed to ${incident.location}`;
                            icon = 'fas fa-spinner';
                            break;
                        default:
                            type = 'pending';
                            text = `${hazardType} reported in ${incident.location}`;
                            icon = 'fas fa-info-circle';
                    }

                    return { type, text, time: timeAgo, icon };
                }) || [];

            } else if (response.status === 401) {
                // User not authenticated, show generic message
                activities = [{
                    type: 'info',
                    text: 'Login to view recent incident activity',
                    time: 'Now',
                    icon: 'fas fa-info-circle'
                }];
            } else {
                throw new Error(`Failed to fetch incidents: ${response.status}`);
            }
        } catch (apiError) {
            console.warn('⚠️ Could not load recent activity:', apiError.message);
            // Show fallback message
            activities = [{
                type: 'info',
                text: 'Unable to load recent activity',
                time: 'Now',
                icon: 'fas fa-exclamation-triangle'
            }];
        }

        activityContainer.innerHTML = activities.map(activity => `
            <div class="activity-item">
                <div class="activity-icon ${activity.type}">
                    <i class="${activity.icon}"></i>
                </div>
                <div class="activity-content">
                    <p class="activity-text">${activity.text}</p>
                    <span class="activity-time">${activity.time}</span>
                </div>
            </div>
        `).join('');

    } catch (error) {
        console.error('❌ Error loading recent activity:', error);
    }
}

/**
 * Load incidents table
 */
async function loadIncidentsTable() {
    try {
        const tableBody = document.querySelector('#incidents-table tbody');
        if (!tableBody) return;

        // Auto-detect column count from the table header
        const headerCells = document.querySelectorAll('#incidents-table thead th');
        const colCount = headerCells.length || 5;

        console.log('🔄 Loading incidents table from database...');

        // Show loading state
        tableBody.innerHTML = `<tr><td colspan="${colCount}" class="loading-cell">Loading incidents...</td></tr>`;

        try {
            // Get recent incidents from API
            const token = localStorage.getItem('oceanGuardToken');
            const headers = {
                'Content-Type': 'application/json'
            };

            if (token) {
                headers['Authorization'] = `Bearer ${token}`;
            }

            const response = await fetch('https://ocean-sentinels.onrender.com/api/incidents/?page=1&size=10', {
                headers: headers
            });

            if (response.ok) {
                const incidentsData = await response.json();
                console.log('✅ Incidents table data loaded:', incidentsData);

                const incidents = incidentsData.incidents || [];

                if (incidents.length === 0) {
                    tableBody.innerHTML = `<tr><td colspan="${colCount}" class="loading-cell">No incidents found</td></tr>`;
                    return;
                }

                // Generate rows based on column structure
                if (colCount <= 5) {
                    // Public table: Date, Type, Region, Status, Severity
                    tableBody.innerHTML = incidents.map(incident => `
                        <tr>
                            <td>${new Date(incident.created_at).toLocaleDateString()}</td>
                            <td>${convertHazardTypeToLabel(incident.hazard_type)}</td>
                            <td>${incident.location}</td>
                            <td><span class="status-badge ${incident.status.toLowerCase().replace('_', '-')}">${incident.status.replace('_', ' ')}</span></td>
                            <td><span class="urgency-badge ${incident.urgency.toLowerCase()}">${incident.urgency.toUpperCase()}</span></td>
                        </tr>
                    `).join('');
                } else {
                    // Full table: Reference ID, Type, Location, Status, Urgency, Date, Actions
                    tableBody.innerHTML = incidents.map(incident => `
                        <tr>
                            <td>${incident.reference_id}</td>
                            <td>${convertHazardTypeToLabel(incident.hazard_type)}</td>
                            <td>${incident.location}</td>
                            <td><span class="status-badge ${incident.status.toLowerCase().replace('_', '-')}">${incident.status.replace('_', ' ')}</span></td>
                            <td><span class="urgency-badge ${incident.urgency.toLowerCase()}">${incident.urgency.toUpperCase()}</span></td>
                            <td>${new Date(incident.created_at).toLocaleDateString()}</td>
                            <td>
                                <button class="btn btn--small btn--secondary" onclick="viewIncident('${incident.reference_id}')">
                                    View
                                </button>
                            </td>
                        </tr>
                    `).join('');
                }

            } else if (response.status === 401) {
                // User not authenticated
                tableBody.innerHTML = `<tr><td colspan="${colCount}" class="loading-cell">Login to view incidents data</td></tr>`;
            } else {
                throw new Error(`Failed to fetch incidents: ${response.status}`);
            }
        } catch (apiError) {
            console.warn('⚠️ Could not load incidents table:', apiError.message);
            tableBody.innerHTML = `<tr><td colspan="${colCount}" class="loading-cell">Unable to load incidents data</td></tr>`;
        }

    } catch (error) {
        console.error('❌ Error loading incidents table:', error);
        const tableBody = document.querySelector('#incidents-table tbody');
        if (tableBody) {
            tableBody.innerHTML = '<tr><td colspan="7" class="loading-cell">Error loading incidents</td></tr>';
        }
    }
}


/**
 * UI Helper Functions
 */

function convertHazardTypeToLabel(type) {
    const typeMap = {
        'high-waves': 'High Waves',
        'flooding': 'Flooding',
        'tsunami': 'Tsunami',
        'lost-vessel': 'Lost Vessel',
        'debris': 'Debris',
        'oil-spill': 'Oil Spill',
        'other': 'Other'
    };
    return typeMap[type] || type.replace(/-/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
}

function getTimeAgo(date) {
    const now = new Date();
    const timeDiff = now - date;
    const seconds = Math.floor(timeDiff / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) {
        return `${days} day${days > 1 ? 's' : ''} ago`;
    } else if (hours > 0) {
        return `${hours} hour${hours > 1 ? 's' : ''} ago`;
    } else if (minutes > 0) {
        return `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
    } else {
        return 'Just now';
    }
}

function showLoading() {
    const loading = document.getElementById('loading-indicator');
    const content = document.getElementById('analytics-content');
    const error = document.getElementById('error-message');

    if (loading) loading.style.display = 'flex';
    if (content) content.style.display = 'none';
    if (error) error.style.display = 'none';
}

function hideLoading() {
    const loading = document.getElementById('loading-indicator');
    if (loading) loading.style.display = 'none';
}

function showContent() {
    const content = document.getElementById('analytics-content');
    const error = document.getElementById('error-message');

    if (content) content.style.display = 'block';
    if (error) error.style.display = 'none';
}

function showError(message) {
    const loading = document.getElementById('loading-indicator');
    const content = document.getElementById('analytics-content');
    const error = document.getElementById('error-message');
    const errorText = document.getElementById('error-text');

    if (loading) loading.style.display = 'none';
    if (content) content.style.display = 'none';
    if (error) error.style.display = 'flex';
    if (errorText) errorText.textContent = message;
}

function updateLastUpdatedTime() {
    const now = new Date();
    const timeString = now.toLocaleString('en-IN', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        timeZone: 'Asia/Kolkata'
    });

    const lastUpdatedElement = document.getElementById('last-updated');
    if (lastUpdatedElement) {
        lastUpdatedElement.textContent = `Last Updated: ${timeString} IST`;
    }
}

/**
 * Export data functionality
 */
function exportData() {
    try {
        if (!analyticsData) {
            alert('No data available to export');
            return;
        }

        const dataToExport = {
            exportDate: new Date().toISOString(),
            dashboard: analyticsData.dashboard,
            timeline: analyticsData.timeline
        };

        const dataStr = JSON.stringify(dataToExport, null, 2);
        const dataBlob = new Blob([dataStr], { type: 'application/json' });

        const url = URL.createObjectURL(dataBlob);
        const downloadLink = document.createElement('a');
        downloadLink.href = url;
        downloadLink.download = `ocean-guard-analytics-${new Date().toISOString().split('T')[0]}.json`;
        downloadLink.click();

        URL.revokeObjectURL(url);

        console.log('✅ Analytics data exported successfully');
    } catch (error) {
        console.error('❌ Error exporting data:', error);
        alert('Failed to export data');
    }
}

/**
 * View incident details
 */
function viewIncident(referenceId) {
    console.log('📋 Viewing incident:', referenceId);
    alert(`Viewing incident: ${referenceId}\n\nThis functionality will be implemented in the next update.`);
}

console.log('🌊 Analytics Dashboard JavaScript Loaded');
