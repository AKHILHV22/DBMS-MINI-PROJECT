async function bookTicket(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const data = {
        passengerId: parseInt(formData.get('passengerId')),
        scheduleId: parseInt(formData.get('scheduleId')),
        sourceStationId: parseInt(formData.get('sourceStationId')),
        destStationId: parseInt(formData.get('destStationId')),
        seatNumber: formData.get('seatNumber'),
        journeyDate: formData.get('journeyDate'),
        fare: parseFloat(formData.get('fare')),
        paymentMethod: formData.get('paymentMethod')
    };
    
    const result = await apiCall('/api/book-ticket', 'POST', data);
    
    if (result.success && result.data && result.data.length > 0) {
        const bookingDetails = result.data[0][0]; // First result set, first row
        showBookingSuccess(bookingDetails);
    } else {
        showToast('Booking failed: ' + (result.error || 'Unknown error'), 'danger');
    }
}

function showBookingSuccess(details) {
    const content = `
        <div class="procedure-result-success">
            <h3><i class="fas fa-check-circle"></i> Ticket Booked Successfully!</h3>
            <div class="booking-details">
                <p><strong>Ticket Number:</strong> ${details.TicketNumber}</p>
                <p><strong>Ticket Code:</strong> ${details.TicketCode}</p>
                <p><strong>Transaction Code:</strong> ${details.TransactionCode}</p>
                <p><strong>Seat:</strong> ${details.SeatNumber}</p>
                <p><strong>Journey Date:</strong> ${formatDate(details.JourneyDate)}</p>
                <p><strong>Amount Paid:</strong> ${formatCurrency(details.Amount)}</p>
            </div>
        </div>
    `;
    
    document.getElementById('modalTitle').textContent = 'Booking Successful';
    document.getElementById('modalContent').innerHTML = content;
    document.getElementById('resultModal').classList.add('active');
}

async function generateReport(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const data = {
        startDate: formData.get('startDate'),
        endDate: formData.get('endDate')
    };
    
    const result = await apiCall('/api/revenue-report', 'POST', data);
    
    if (result.success && result.data) {
        displayRevenueReport(result.data);
    } else {
        showToast('Report generation failed: ' + (result.error || 'Unknown error'), 'danger');
    }
}

function displayRevenueReport(reportData) {
    let html = '<div class="revenue-report">';
    
    // Summary
    if (reportData[0] && reportData[0].length > 0) {
        const summary = reportData[0][0];
        html += `
            <div class="report-section">
                <h3><i class="fas fa-chart-line"></i> Revenue Summary (${formatCurrency(summary.TotalRevenue)})</h3>
                <div class="stats-grid" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin-top: 1rem;">
                    <div class="stat-card" style="background: linear-gradient(135deg, #2dd4bf 0%, #14b8a6 100%); color: white; padding: 1.5rem; border-radius: 12px; text-align: center;">
                        <div style="font-size: 2rem; font-weight: 700; margin-bottom: 0.5rem;">${summary.TotalTransactions}</div>
                        <div style="opacity: 0.9; font-size: 0.9rem;">Total Transactions</div>
                    </div>
                    <div class="stat-card" style="background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%); color: white; padding: 1.5rem; border-radius: 12px; text-align: center;">
                        <div style="font-size: 2rem; font-weight: 700; margin-bottom: 0.5rem;">${formatCurrency(summary.TotalRevenue)}</div>
                        <div style="opacity: 0.9; font-size: 0.9rem;">Total Revenue</div>
                    </div>
                    <div class="stat-card" style="background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%); color: white; padding: 1.5rem; border-radius: 12px; text-align: center;">
                        <div style="font-size: 2rem; font-weight: 700; margin-bottom: 0.5rem;">${formatCurrency(summary.AverageTransaction)}</div>
                        <div style="opacity: 0.9; font-size: 0.9rem;">Average Transaction</div>
                    </div>
                    <div class="stat-card" style="background: linear-gradient(135deg, #ec4899 0%, #db2777 100%); color: white; padding: 1.5rem; border-radius: 12px; text-align: center;">
                        <div style="font-size: 1.2rem; font-weight: 600; margin-bottom: 0.25rem;">Min: ${formatCurrency(summary.MinTransaction)}</div>
                        <div style="font-size: 1.2rem; font-weight: 600;">Max: ${formatCurrency(summary.MaxTransaction)}</div>
                    </div>
                </div>
            </div>
        `;
    }
    
    // By Payment Method
    if (reportData[1] && reportData[1].length > 0) {
        html += `
            <div class="report-section" style="margin-top: 2rem; background: white; padding: 1.5rem; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                <h3><i class="fas fa-credit-card"></i> Revenue by Payment Method</h3>
                <div style="overflow-x: auto;">
                    <table class="data-table" style="width: 100%; margin-top: 1rem;">
                        <thead>
                            <tr style="background: #f0fdfa;">
                                <th style="padding: 1rem; text-align: left; color: #134e4a;">Payment Method</th>
                                <th style="padding: 1rem; text-align: center; color: #134e4a;">Transactions</th>
                                <th style="padding: 1rem; text-align: right; color: #134e4a;">Revenue</th>
                                <th style="padding: 1rem; text-align: center; color: #134e4a;">Share</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${reportData[1].map((row, index) => {
                                const colors = ['#2dd4bf', '#3b82f6', '#8b5cf6', '#ec4899', '#f59e0b', '#10b981'];
                                const color = colors[index % colors.length];
                                return `
                                <tr style="border-bottom: 1px solid #e5e7eb;">
                                    <td style="padding: 1rem;">
                                        <strong style="color: ${color};">${row.PaymentMethod}</strong>
                                    </td>
                                    <td style="padding: 1rem; text-align: center;">${row.TransactionCount}</td>
                                    <td style="padding: 1rem; text-align: right; font-weight: 600;">${formatCurrency(row.MethodRevenue)}</td>
                                    <td style="padding: 1rem; text-align: center;">
                                        <div style="background: ${color}20; color: ${color}; padding: 0.25rem 0.75rem; border-radius: 20px; display: inline-block; font-weight: 600;">
                                            ${row.RevenuePercentage}%
                                        </div>
                                    </td>
                                </tr>
                                `;
                            }).join('')}
                        </tbody>
                    </table>
                </div>
            </div>
        `;
    }
    
    // By Type
    if (reportData[2] && reportData[2].length > 0) {
        html += `
            <div class="report-section" style="margin-top: 2rem; background: white; padding: 1.5rem; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                <h3><i class="fas fa-chart-pie"></i> Revenue by Type</h3>
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1.5rem; margin-top: 1rem;">
                    ${reportData[2].map((row, index) => {
                        const colors = [
                            { bg: 'linear-gradient(135deg, #2dd4bf 0%, #14b8a6 100%)', icon: 'fa-ticket' },
                            { bg: 'linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)', icon: 'fa-id-card' },
                            { bg: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)', icon: 'fa-money-bill' }
                        ];
                        const style = colors[index % colors.length];
                        return `
                            <div style="background: ${style.bg}; color: white; padding: 1.5rem; border-radius: 12px;">
                                <div style="display: flex; align-items: center; gap: 1rem; margin-bottom: 1rem;">
                                    <i class="fas ${style.icon}" style="font-size: 2rem; opacity: 0.8;"></i>
                                    <div>
                                        <div style="font-size: 0.9rem; opacity: 0.9;">${row.RevenueType}</div>
                                        <div style="font-size: 1.8rem; font-weight: 700;">${formatCurrency(row.TypeRevenue)}</div>
                                    </div>
                                </div>
                                <div style="opacity: 0.9; font-size: 0.9rem;">${row.SalesCount} transactions</div>
                            </div>
                        `;
                    }).join('')}
                </div>
            </div>
        `;
    }
    
    // Daily Trend
    if (reportData[3] && reportData[3].length > 0) {
        html += `
            <div class="report-section" style="margin-top: 2rem; background: white; padding: 1.5rem; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                <h3><i class="fas fa-chart-area"></i> Daily Revenue Trend</h3>
                <div style="overflow-x: auto; margin-top: 1rem;">
                    <table class="data-table" style="width: 100%;">
                        <thead>
                            <tr style="background: #f0fdfa;">
                                <th style="padding: 1rem; text-align: left; color: #134e4a;">Date</th>
                                <th style="padding: 1rem; text-align: center; color: #134e4a;">Transactions</th>
                                <th style="padding: 1rem; text-align: right; color: #134e4a;">Revenue</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${reportData[3].map(row => `
                                <tr style="border-bottom: 1px solid #e5e7eb;">
                                    <td style="padding: 1rem;">${formatDate(row.RevenueDate)}</td>
                                    <td style="padding: 1rem; text-align: center;">${row.DailyTransactions}</td>
                                    <td style="padding: 1rem; text-align: right; font-weight: 600; color: #14b8a6;">${formatCurrency(row.DailyRevenue)}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            </div>
        `;
    }
    
    html += '</div>';
    
    document.getElementById('reportResults').style.display = 'block';
    document.getElementById('reportContent').innerHTML = html;
    
    // Scroll to results
    document.getElementById('reportResults').scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function closeResultModal() {
    document.getElementById('resultModal').classList.remove('active');
}

window.onclick = function(event) {
    const modal = document.getElementById('resultModal');
    if (event.target === modal) closeResultModal();
}
