async function loadDailyBookings() {
    const result = await apiCall('/api/reports/daily-bookings');
    
    if (result.success && result.data) {
        displayDailyBookingsChart(result.data);
        displayDailyBookingsTable(result.data);
    }
}

async function loadPopularRoutes() {
    const result = await apiCall('/api/reports/popular-routes');
    
    if (result.success && result.data) {
        displayPopularRoutesChart(result.data);
        displayPopularRoutesTable(result.data);
    }
}

async function loadPaymentMethods() {
    const result = await apiCall('/api/query/aggregate');
    
    if (result.success && result.data) {
        displayPaymentMethodsChart(result.data);
    }
}

async function loadPassengerAnalytics() {
    showToast('Loading passenger analytics...', 'info');
    // Placeholder for passenger analytics
}

function displayDailyBookingsChart(data) {
    const container = document.getElementById('dailyBookingsChart');
    let html = '<div class="chart-placeholder"><h4>Daily Bookings Trend</h4>';
    
    data.forEach(row => {
        const percentage = (row.TotalBookings / Math.max(...data.map(r => r.TotalBookings))) * 100;
        html += `
            <div class="chart-bar">
                <span class="chart-label">${formatDate(row.BookingDate)}</span>
                <div class="chart-bar-fill" style="width: ${percentage}%"></div>
                <span class="chart-value">${row.TotalBookings} bookings</span>
            </div>
        `;
    });
    
    html += '</div>';
    container.innerHTML = html;
    container.style.display = 'block';
}

function displayDailyBookingsTable(data) {
    const tbody = document.getElementById('bookingsBody');
    tbody.innerHTML = data.map(row => `
        <tr>
            <td>${formatDate(row.BookingDate)}</td>
            <td>${row.TotalBookings}</td>
            <td>${formatCurrency(row.Revenue)}</td>
            <td>${row.UniquePassengers}</td>
            <td>${formatCurrency(row.Revenue / row.TotalBookings)}</td>
        </tr>
    `).join('');
}

function displayPopularRoutesChart(data) {
    const container = document.getElementById('popularRoutesChart');
    let html = '<div class="chart-placeholder"><h4>Top Routes by Bookings</h4>';
    
    data.forEach(row => {
        const percentage = (row.BookingCount / Math.max(...data.map(r => r.BookingCount))) * 100;
        html += `
            <div class="chart-bar">
                <span class="chart-label">${row.RouteCode} - ${row.Name}</span>
                <div class="chart-bar-fill" style="width: ${percentage}%; background: linear-gradient(135deg, #10b981 0%, #059669 100%)"></div>
                <span class="chart-value">${row.BookingCount} bookings</span>
            </div>
        `;
    });
    
    html += '</div>';
    container.innerHTML = html;
    container.style.display = 'block';
}

function displayPopularRoutesTable(data) {
    const tbody = document.getElementById('routesBody');
    tbody.innerHTML = data.map(row => `
        <tr>
            <td>${row.RouteCode}</td>
            <td>${row.Name}</td>
            <td>${row.BookingCount}</td>
            <td>${formatCurrency(row.TotalRevenue)}</td>
            <td>${formatCurrency(row.TotalRevenue / row.BookingCount)}</td>
        </tr>
    `).join('');
}

function displayPaymentMethodsChart(data) {
    const container = document.getElementById('paymentMethodsChart');
    let html = '<div class="chart-placeholder"><h4>Payment Method Distribution</h4>';
    
    const total = data.reduce((sum, row) => sum + parseFloat(row.TotalRevenue), 0);
    
    data.forEach(row => {
        const percentage = (parseFloat(row.TotalRevenue) / total) * 100;
        html += `
            <div class="chart-bar">
                <span class="chart-label">${row.PaymentMethod}</span>
                <div class="chart-bar-fill" style="width: ${percentage}%; background: linear-gradient(135deg, #06b6d4 0%, #0891b2 100%)"></div>
                <span class="chart-value">${percentage.toFixed(1)}%</span>
            </div>
        `;
    });
    
    html += '</div>';
    container.innerHTML = html;
    container.style.display = 'block';
}

function showTab(tabName) {
    document.querySelectorAll('.tab-content').forEach(tab => tab.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
    
    document.getElementById(tabName + 'Tab').classList.add('active');
    event.target.classList.add('active');
}
