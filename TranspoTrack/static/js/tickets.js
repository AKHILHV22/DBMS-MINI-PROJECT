document.addEventListener('DOMContentLoaded', () => {
    loadTickets();
});

async function loadTickets() {
    showLoading('ticketsBody');
    const result = await apiCall('/api/tickets');
    
    if (result.success && result.data) {
        const tbody = document.getElementById('ticketsBody');
        if (result.data.length === 0) {
            showNoData('ticketsBody', 'No tickets found');
            return;
        }
        tbody.innerHTML = result.data.map(t => `
            <tr>
                <td>${t.TicketNumber}</td>
                <td>${t.TicketCode}</td>
                <td>${t.PassengerName}</td>
                <td>${t.SourceStation}</td>
                <td>${t.DestinationStation}</td>
                <td>${formatDate(t.JourneyDate)}</td>
                <td>${t.SeatNumber}</td>
                <td>${formatCurrency(t.Fare)}</td>
                <td>${getStatusBadge(t.TicketStatus)}</td>
            </tr>
        `).join('');
    } else {
        showError('ticketsBody', result.error || 'Failed to load tickets');
    }
}

function filterTickets() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();
    const rows = document.querySelectorAll('#ticketsBody tr');
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}
