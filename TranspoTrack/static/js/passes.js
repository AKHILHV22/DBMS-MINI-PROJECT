document.addEventListener('DOMContentLoaded', () => {
    loadPasses();
});

async function loadPasses() {
    showLoading('passesBody');
    const result = await apiCall('/api/passes');
    
    if (result.success && result.data) {
        const tbody = document.getElementById('passesBody');
        if (result.data.length === 0) {
            showNoData('passesBody', 'No passes found');
            return;
        }
        tbody.innerHTML = result.data.map(p => `
            <tr>
                <td>${p.PassID}</td>
                <td>${p.PassCode}</td>
                <td>${p.PassengerName}</td>
                <td><span class="badge badge-primary">${p.PassType}</span></td>
                <td>${formatDate(p.StartDate)}</td>
                <td>${formatDate(p.EndDate)}</td>
                <td>${formatCurrency(p.Price)}</td>
                <td>${getStatusBadge(p.PassStatus)}</td>
            </tr>
        `).join('');
    } else {
        showError('passesBody', result.error || 'Failed to load passes');
    }
}

function filterPasses() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();
    const rows = document.querySelectorAll('#passesBody tr');
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}
