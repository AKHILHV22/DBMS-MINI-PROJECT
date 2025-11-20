let queriesRunCount = 0;

async function runNestedQuery() {
    const resultDiv = document.getElementById('nestedResult');
    resultDiv.innerHTML = '<div class="loading-spinner"></div><p>Executing nested query...</p>';
    resultDiv.style.display = 'block';
    
    const startTime = Date.now();
    const result = await apiCall('/api/query/nested');
    const endTime = Date.now();
    
    updatePerformance(endTime - startTime, result.data ? result.data.length : 0);
    
    if (result.success && result.data) {
        displayQueryResult(resultDiv, result.data, 'Nested Query Results', [
            'Passenger ID', 'Name', 'Total Tickets', 'Total Spending'
        ]);
    } else {
        resultDiv.innerHTML = `<div class="query-error"><i class="fas fa-exclamation-circle"></i> Error: ${result.error}</div>`;
    }
}

async function runJoinQuery() {
    const resultDiv = document.getElementById('joinResult');
    resultDiv.innerHTML = '<div class="loading-spinner"></div><p>Executing join query...</p>';
    resultDiv.style.display = 'block';
    
    const startTime = Date.now();
    const result = await apiCall('/api/query/join');
    const endTime = Date.now();
    
    updatePerformance(endTime - startTime, result.data ? result.data.length : 0);
    
    if (result.success && result.data) {
        displayQueryResult(resultDiv, result.data, 'Join Query Results', [
            'Route Code', 'Route Name', 'Total Distance', 'Stations', 'Station Count'
        ]);
    } else {
        resultDiv.innerHTML = `<div class="query-error"><i class="fas fa-exclamation-circle"></i> Error: ${result.error}</div>`;
    }
}

async function runAggregateQuery() {
    const resultDiv = document.getElementById('aggregateResult');
    resultDiv.innerHTML = '<div class="loading-spinner"></div><p>Executing aggregate query...</p>';
    resultDiv.style.display = 'block';
    
    const startTime = Date.now();
    const result = await apiCall('/api/query/aggregate');
    const endTime = Date.now();
    
    updatePerformance(endTime - startTime, result.data ? result.data.length : 0);
    
    if (result.success && result.data) {
        displayQueryResult(resultDiv, result.data, 'Aggregate Query Results', [
            'Payment Method', 'Transaction Count', 'Total Revenue', 'Average Amount', 'Min Amount', 'Max Amount'
        ]);
    } else {
        resultDiv.innerHTML = `<div class="query-error"><i class="fas fa-exclamation-circle"></i> Error: ${result.error}</div>`;
    }
}

function displayQueryResult(container, data, title, headers) {
    if (data.length === 0) {
        container.innerHTML = `<div class="query-no-data"><i class="fas fa-info-circle"></i> No data returned</div>`;
        return;
    }
    
    let html = `<div class="query-result-container"><h3>${title}</h3><div class="table-container"><table class="data-table"><thead><tr>`;
    
    headers.forEach(header => {
        html += `<th>${header}</th>`;
    });
    html += '</tr></thead><tbody>';
    
    data.forEach(row => {
        html += '<tr>';
        Object.values(row).forEach(value => {
            if (typeof value === 'number' && value > 100) {
                html += `<td>${formatCurrency(value)}</td>`;
            } else {
                html += `<td>${value !== null ? value : 'N/A'}</td>`;
            }
        });
        html += '</tr>';
    });
    
    html += '</tbody></table></div></div>';
    container.innerHTML = html;
}

async function runAllQueries() {
    const resultDiv = document.getElementById('allResults');
    resultDiv.innerHTML = '<div class="loading-spinner"></div><p>Executing all queries...</p>';
    resultDiv.style.display = 'block';
    
    const startTime = Date.now();
    
    const [nested, join, aggregate] = await Promise.all([
        apiCall('/api/query/nested'),
        apiCall('/api/query/join'),
        apiCall('/api/query/aggregate')
    ]);
    
    const endTime = Date.now();
    const totalRows = (nested.data?.length || 0) + (join.data?.length || 0) + (aggregate.data?.length || 0);
    
    updatePerformance(endTime - startTime, totalRows);
    
    let html = '<div class="all-queries-results">';
    
    if (nested.success && nested.data) {
        html += '<div class="query-section">';
        displayQueryResult({ innerHTML: '' }, nested.data, 'Nested Query: High-Value Passengers', 
            ['Passenger ID', 'Name', 'Total Tickets', 'Total Spending']);
        html += document.querySelector('.query-result-container')?.outerHTML || '';
        html += '</div>';
    }
    
    if (join.success && join.data) {
        html += '<div class="query-section">';
        const tempDiv = document.createElement('div');
        displayQueryResult(tempDiv, join.data, 'Join Query: Route Details', 
            ['Route Code', 'Route Name', 'Total Distance', 'Stations', 'Station Count']);
        html += tempDiv.innerHTML;
        html += '</div>';
    }
    
    if (aggregate.success && aggregate.data) {
        html += '<div class="query-section">';
        const tempDiv = document.createElement('div');
        displayQueryResult(tempDiv, aggregate.data, 'Aggregate Query: Payment Methods', 
            ['Payment Method', 'Transaction Count', 'Total Revenue', 'Average Amount', 'Min Amount', 'Max Amount']);
        html += tempDiv.innerHTML;
        html += '</div>';
    }
    
    html += '</div>';
    resultDiv.innerHTML = html;
}

function updatePerformance(execTime, rowCount) {
    queriesRunCount++;
    document.getElementById('execTime').textContent = execTime + ' ms';
    document.getElementById('rowsProcessed').textContent = rowCount;
    document.getElementById('queriesRun').textContent = queriesRunCount;
}
