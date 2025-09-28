document.addEventListener('DOMContentLoaded', () => {

    // For an MVP, we use mock data. In a real application, this data would be fetched
    // from your FastAPI backend, e.g., via fetch('/api/analytics/summary?range=30d')
    const mockData = {
        timeline: {
            labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
            data: [65, 59, 80, 81]
        },
        distribution: {
            labels: ['Flooding', 'High Waves', 'Debris', 'Other'],
            data: [300, 150, 100, 50]
        },
        efficiency: {
            labels: ['Flooding', 'High Waves', 'Debris', 'Other'],
            data: [5.5, 8.2, 3.1, 6.7] // Average hours to resolve
        }
    };

    // --- 1. Incident Timeline Chart (Line Chart) ---
    const timelineCtx = document.getElementById('incidentTimelineChart');
    if (timelineCtx) {
        new Chart(timelineCtx, {
            type: 'line',
            data: {
                labels: mockData.timeline.labels,
                datasets: [{
                    label: '# of Reports',
                    data: mockData.timeline.data,
                    fill: true,
                    borderColor: 'rgb(0, 90, 156)',
                    backgroundColor: 'rgba(0, 90, 156, 0.1)',
                    tension: 0.1
                }]
            },
            options: {
                scales: {
                    y: {
                        beginAtZero: true
                    }
                },
                responsive: true
            }
        });
    }

    // --- 2. Hazard Distribution Chart (Doughnut Chart) ---
    const distributionCtx = document.getElementById('hazardDistributionChart');
    if (distributionCtx) {
        new Chart(distributionCtx, {
            type: 'doughnut',
            data: {
                labels: mockData.distribution.labels,
                datasets: [{
                    label: 'Hazard Distribution',
                    data: mockData.distribution.data,
                    backgroundColor: [
                        'rgb(0, 90, 156)',
                        'rgb(255, 193, 7)',
                        'rgb(220, 53, 69)',
                        'rgb(108, 117, 125)'
                    ],
                    hoverOffset: 4
                }]
            },
            options: {
                responsive: true
            }
        });
    }

    // --- 3. Response Efficiency Chart (Bar Chart) ---
    const efficiencyCtx = document.getElementById('responseEfficiencyChart');
    if (efficiencyCtx) {
        new Chart(efficiencyCtx, {
            type: 'bar',
            data: {
                labels: mockData.efficiency.labels,
                datasets: [{
                    label: 'Avg. Hours to Resolve',
                    data: mockData.efficiency.data,
                    backgroundColor: [
                        'rgba(0, 90, 156, 0.7)',
                        'rgba(255, 193, 7, 0.7)',
                        'rgba(220, 53, 69, 0.7)',
                        'rgba(108, 117, 125, 0.7)'
                    ]
                }]
            },
            options: {
                scales: {
                    y: {
                        beginAtZero: true
                    }
                },
                responsive: true
            }
        });
    }
});
