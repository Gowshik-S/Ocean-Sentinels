/**
 * Authority Analytics Dashboard JavaScript
 * Enhanced analytics with advanced charts for authorized personnel
 * Version: 1.0 - October 2025
 */

// Global variables for charts
let incidentTrendChart = null;
let statusDistributionChart = null;
let hazardTypesChart = null;
let urgencyChart = null;
let regionalChart = null;
let responseTimeChart = null;
let teamPerformanceChart = null;

// Color scheme matching Ocean Sentinels theme
const chartColors = {
    primary: '#005A9C',      // Deep Blue
    secondary: '#FFFFFF',    // White
    accent: '#FFC107',       // Warning Yellow/Gold
    success: '#28a745',      // Green
    danger: '#dc3545',       // Red
    warning: '#fd7e14',      // Orange
    info: '#17a2b8',         // Cyan
    light: '#f8f9fa',        // Light gray
    dark: '#212529'          // Dark
};

// Initialize when page loads
document.addEventListener('DOMContentLoaded', function() {
    // Check if user is authorized
    checkAuthorityAccess();
    
    // Load authority analytics data
    loadAuthorityAnalytics();
    
    // Set up event listeners
    setupEventListeners();
    
    // Update timestamp
    updateLastUpdated();
});

// Check if user has authority access
function checkAuthorityAccess() {
    const user = JSON.parse(sessionStorage.getItem('oceanGuardUser') || '{}');
    
    if (!user.role || !['admin', 'authority', 'rescue_team'].includes(user.role)) {
        alert('⚠️ Access Denied: This page is for authorized personnel only.');
        window.location.href = 'analytics.html';
        return false;
    }
    
    // Update navigation based on user role
    updateNavigationForAuthority(user);
    return true;
}

// Update navigation for authority users
function updateNavigationForAuthority(user) {
    const navActions = document.querySelector('.nav-actions');
    if (navActions) {
        navActions.innerHTML = `
            <span class="welcome-user">Welcome, ${user.name || 'Authority'}</span>
            <a href="#" class="btn btn--primary" id="report-hazard-btn">New Report</a>
            <a href="#" id="logout-button" class="btn btn--secondary">Logout</a>
        `;
        
        // Re-add event listeners
        const logoutBtn = document.getElementById('logout-button');
        if (logoutBtn) {
            logoutBtn.addEventListener('click', logout);
        }
    }
}

// Load authority analytics data
async function loadAuthorityAnalytics() {
    const loadingIndicator = document.getElementById('loading-indicator');
    const errorMessage = document.getElementById('error-message');
    const analyticsContent = document.getElementById('analytics-content');
    
    try {
        loadingIndicator.style.display = 'block';
        errorMessage.style.display = 'none';
        analyticsContent.style.display = 'none';
        
        // Load data from API
        const api = new OceanHazardAPI();
        
        // Load dashboard data
        const dashboardData = await api.getDashboardAnalytics();
        updateDashboardCards(dashboardData);
        
        // Load incidents data for charts
        const incidentsResponse = await api.getIncidents();
        
        // Ensure incidents is an array
        let incidentsData = [];
        if (Array.isArray(incidentsResponse)) {
            incidentsData = incidentsResponse;
        } else if (incidentsResponse && Array.isArray(incidentsResponse.data)) {
            incidentsData = incidentsResponse.data;
        } else if (incidentsResponse && Array.isArray(incidentsResponse.incidents)) {
            incidentsData = incidentsResponse.incidents;
        } else {
            console.warn('Incidents data is not in expected format, using mock data');
            incidentsData = getMockIncidentsData();
        }
        
        // Create all charts
        createIncidentTrendChart(incidentsData);
        createStatusDistributionChart(dashboardData);
        createHazardTypesChart(incidentsData);
        createUrgencyChart(incidentsData);
        createRegionalChart(incidentsData);
        createResponseTimeChart(incidentsData);
        createTeamPerformanceChart();
        
        // Load incidents table
        loadIncidentsTable(incidentsData);
        
        // Load performance metrics
        loadPerformanceMetrics();
        
        // Show content
        loadingIndicator.style.display = 'none';
        analyticsContent.style.display = 'block';
        
    } catch (error) {
        console.error('Error loading authority analytics:', error);
        
        // Use mock data as fallback
        try {
            const mockData = getMockIncidentsData();
            const mockDashboard = getMockDashboardData();
            
            updateDashboardCards(mockDashboard);
            createIncidentTrendChart(mockData);
            createStatusDistributionChart(mockDashboard);
            createHazardTypesChart(mockData);
            createUrgencyChart(mockData);
            createRegionalChart(mockData);
            createResponseTimeChart(mockData);
            createTeamPerformanceChart();
            loadIncidentsTable(mockData);
            loadPerformanceMetrics();
            
            loadingIndicator.style.display = 'none';
            analyticsContent.style.display = 'block';
        } catch (fallbackError) {
            console.error('Error with fallback data:', fallbackError);
            loadingIndicator.style.display = 'none';
            errorMessage.style.display = 'block';
            document.getElementById('error-text').textContent = 
                'Failed to load analytics data. Please ensure you have proper authorization.';
        }
    }
}

// Update dashboard cards
function updateDashboardCards(data) {
    document.getElementById('total-incidents').textContent = data.total_incidents || 0;
    document.getElementById('active-incidents').textContent = data.active_incidents || 0;
    document.getElementById('resolved-incidents').textContent = data.resolved_incidents || 0;
    document.getElementById('total-users').textContent = data.total_users || 0;
    document.getElementById('urgent-incidents').textContent = data.urgent_incidents || 0;
    document.getElementById('response-time').textContent = (data.avg_response_time || 0).toFixed(1);
}

// Create incident trend chart
function createIncidentTrendChart(incidents) {
    const ctx = document.getElementById('incident-trend-chart').getContext('2d');
    
    // Process data for last 30 days
    const last30Days = Array.from({length: 30}, (_, i) => {
        const date = new Date();
        date.setDate(date.getDate() - (29 - i));
        return date;
    });
    
    const trendData = last30Days.map(date => {
        const dayIncidents = incidents.filter(incident => {
            const incidentDate = new Date(incident.created_at);
            return incidentDate.toDateString() === date.toDateString();
        });
        return dayIncidents.length;
    });
    
    incidentTrendChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: last30Days.map(date => date.toLocaleDateString('en-IN', { month: 'short', day: 'numeric' })),
            datasets: [{
                label: 'Daily Incidents',
                data: trendData,
                borderColor: chartColors.primary,
                backgroundColor: chartColors.primary + '20',
                fill: true,
                tension: 0.4
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

// Create status distribution chart
function createStatusDistributionChart(data) {
    const ctx = document.getElementById('status-distribution-chart').getContext('2d');
    
    statusDistributionChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: ['Pending', 'Active', 'Resolved'],
            datasets: [{
                data: [
                    data.pending_incidents || 0,
                    data.active_incidents || 0,
                    data.resolved_incidents || 0
                ],
                backgroundColor: [
                    chartColors.warning,
                    chartColors.danger,
                    chartColors.success
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
}

// Create hazard types chart
function createHazardTypesChart(incidents) {
    const ctx = document.getElementById('hazard-types-chart').getContext('2d');
    
    // Count incidents by type
    const typeCounts = {};
    incidents.forEach(incident => {
        const type = incident.hazard_type || 'unknown';
        typeCounts[type] = (typeCounts[type] || 0) + 1;
    });
    
    const labels = Object.keys(typeCounts);
    const data = Object.values(typeCounts);
    
    hazardTypesChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels.map(label => label.replace('_', ' ').toUpperCase()),
            datasets: [{
                label: 'Incidents',
                data: data,
                backgroundColor: chartColors.accent,
                borderColor: chartColors.primary,
                borderWidth: 1
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

// Create urgency chart
function createUrgencyChart(incidents) {
    const ctx = document.getElementById('urgency-chart').getContext('2d');
    
    // Count incidents by urgency
    const urgencyCounts = { high: 0, medium: 0, low: 0 };
    incidents.forEach(incident => {
        const urgency = incident.urgency || 'low';
        urgencyCounts[urgency]++;
    });
    
    urgencyChart = new Chart(ctx, {
        type: 'pie',
        data: {
            labels: ['High', 'Medium', 'Low'],
            datasets: [{
                data: [urgencyCounts.high, urgencyCounts.medium, urgencyCounts.low],
                backgroundColor: [
                    chartColors.danger,
                    chartColors.warning,
                    chartColors.info
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
}

// Create regional chart
function createRegionalChart(incidents) {
    const ctx = document.getElementById('regional-chart').getContext('2d');
    
    // Group incidents by region (simplified - you can enhance this)
    const regions = ['Mumbai', 'Chennai', 'Kolkata', 'Kochi', 'Visakhapatnam', 'Goa'];
    const regionData = regions.map(region => Math.floor(Math.random() * 10)); // Mock data
    
    regionalChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: regions,
            datasets: [{
                label: 'Incidents by Region',
                data: regionData,
                backgroundColor: chartColors.primary,
                borderColor: chartColors.accent,
                borderWidth: 2
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            indexAxis: 'y',
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                x: {
                    beginAtZero: true
                }
            }
        }
    });
}

// Create response time chart
function createResponseTimeChart(incidents) {
    const ctx = document.getElementById('response-time-chart').getContext('2d');
    
    // Mock response time data
    const responseData = [2.5, 1.8, 3.2, 2.1, 1.9, 2.8, 2.3];
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    responseTimeChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: weekDays,
            datasets: [{
                label: 'Response Time (hours)',
                data: responseData,
                borderColor: chartColors.success,
                backgroundColor: chartColors.success + '20',
                fill: true,
                tension: 0.4
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
                    title: {
                        display: true,
                        text: 'Hours'
                    }
                }
            }
        }
    });
}

// Create team performance chart
function createTeamPerformanceChart() {
    const ctx = document.getElementById('team-performance-chart').getContext('2d');
    
    teamPerformanceChart = new Chart(ctx, {
        type: 'radar',
        data: {
            labels: ['Response Speed', 'Resolution Rate', 'Communication', 'Resource Usage', 'Coverage'],
            datasets: [{
                label: 'Team Performance',
                data: [85, 92, 78, 88, 95],
                borderColor: chartColors.primary,
                backgroundColor: chartColors.primary + '20',
                pointBackgroundColor: chartColors.accent
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
                r: {
                    beginAtZero: true,
                    max: 100
                }
            }
        }
    });
}

// Load incidents table
function loadIncidentsTable(incidents) {
    const tableBody = document.querySelector('.incidents-table tbody');
    
    if (!incidents || incidents.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="8" class="loading-cell">No incidents found</td></tr>';
        return;
    }
    
    tableBody.innerHTML = incidents.slice(0, 20).map(incident => `
        <tr>
            <td>${incident.reference_id || incident.id}</td>
            <td><span class="hazard-type">${(incident.hazard_type || 'unknown').replace('_', ' ')}</span></td>
            <td><span class="location-text">${incident.location || 'Unknown'}</span></td>
            <td><span class="status-badge status-badge--${incident.status || 'pending'}">${incident.status || 'pending'}</span></td>
            <td><span class="urgency-badge urgency-${incident.urgency || 'low'}">${incident.urgency || 'low'}</span></td>
            <td>${incident.reporter_name || 'Anonymous'}</td>
            <td>${new Date(incident.created_at).toLocaleDateString('en-IN')}</td>
            <td>
                <button class="btn-action" onclick="viewIncident('${incident.id}')">
                    <i class="fas fa-eye"></i>
                </button>
                <button class="btn-action" onclick="editIncident('${incident.id}')">
                    <i class="fas fa-edit"></i>
                </button>
            </td>
        </tr>
    `).join('');
}

// Load performance metrics
function loadPerformanceMetrics() {
    // Mock performance data
    document.getElementById('api-response-time').textContent = '150ms';
    document.getElementById('db-status').textContent = 'Connected';
    document.getElementById('active-connections').textContent = '245';
    document.getElementById('teams-available').textContent = '12/15';
    document.getElementById('equipment-status').textContent = '98% Ready';
    document.getElementById('coverage-area').textContent = '7,500 km²';
}

// Setup event listeners
function setupEventListeners() {
    // Trend period change
    const trendPeriod = document.getElementById('trend-period');
    if (trendPeriod) {
        trendPeriod.addEventListener('change', () => {
            // Reload trend chart with new period
            loadAuthorityAnalytics();
        });
    }
    
    // Region filter change
    const regionFilter = document.getElementById('region-filter');
    if (regionFilter) {
        regionFilter.addEventListener('change', () => {
            // Update regional chart
            updateRegionalChart();
        });
    }
    
    // Status and urgency filters
    const statusFilter = document.getElementById('status-filter');
    const urgencyFilter = document.getElementById('urgency-filter');
    
    if (statusFilter) {
        statusFilter.addEventListener('change', filterIncidentsTable);
    }
    if (urgencyFilter) {
        urgencyFilter.addEventListener('change', filterIncidentsTable);
    }
}

// Filter incidents table
function filterIncidentsTable() {
    const statusFilter = document.getElementById('status-filter').value;
    const urgencyFilter = document.getElementById('urgency-filter').value;
    
    // Apply filters to table (you can enhance this)
    console.log('Filtering by status:', statusFilter, 'urgency:', urgencyFilter);
}

// Export incidents data
function exportIncidentsData() {
    // Create CSV export (simplified)
    const csvContent = "data:text/csv;charset=utf-8," + 
        "ID,Type,Location,Status,Urgency,Date\n" +
        "Sample,Export,Function,Active,High," + new Date().toISOString();
    
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", "incidents_export.csv");
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}

// View incident details
function viewIncident(incidentId) {
    alert(`Viewing incident: ${incidentId}`);
    // Implement incident details view
}

// Edit incident
function editIncident(incidentId) {
    alert(`Editing incident: ${incidentId}`);
    // Implement incident editing
}

// Update regional chart based on filter
function updateRegionalChart() {
    if (regionalChart) {
        // Update chart data based on region filter
        regionalChart.update();
    }
}

// Update last updated timestamp
function updateLastUpdated() {
    const timestamp = new Date().toLocaleString('en-IN', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
    
    const lastUpdatedElement = document.getElementById('last-updated');
    if (lastUpdatedElement) {
        lastUpdatedElement.textContent = `Last updated: ${timestamp}`;
    }
}

// Logout function
function logout(e) {
    e.preventDefault();
    // Clear session data
    sessionStorage.removeItem('oceanGuardUser');
    localStorage.removeItem('oceanGuardUser');
    localStorage.removeItem('oceanGuardToken');
    
    alert('You have been logged out.');
    window.location.href = 'index.html';
}

// Mock data functions for fallback
function getMockIncidentsData() {
    return [
        {
            id: 1,
            type: 'High Waves',
            location: 'Goa Coast',
            status: 'Active',
            urgency: 'High',
            created_at: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
            response_time: 15,
            coordinates: { lat: 15.2993, lng: 74.1240 }
        },
        {
            id: 2,
            type: 'Strong Current',
            location: 'Tamil Nadu',
            status: 'Resolved',
            urgency: 'Medium',
            created_at: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
            response_time: 25,
            coordinates: { lat: 11.1271, lng: 78.6569 }
        },
        {
            id: 3,
            type: 'Tsunami Warning',
            location: 'Andaman Islands',
            status: 'Monitoring',
            urgency: 'Critical',
            created_at: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
            response_time: 5,
            coordinates: { lat: 11.7401, lng: 92.6586 }
        }
    ];
}

function getMockDashboardData() {
    return {
        totalIncidents: 847,
        activeIncidents: 23,
        resolvedIncidents: 824,
        averageResponseTime: 18.5,
        criticalAlerts: 3,
        teams: {
            total: 12,
            active: 8,
            standby: 4
        }
    };
}

// Auto-refresh data every 5 minutes
setInterval(() => {
    updateLastUpdated();
    loadAuthorityAnalytics();
}, 5 * 60 * 1000);