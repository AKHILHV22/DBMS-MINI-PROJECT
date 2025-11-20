function showTriggerTest(testType) {
    const modal = document.getElementById('testResultModal');
    const title = document.getElementById('testTitle');
    const content = document.getElementById('testContent');
    
    const testResults = {
        'payment-valid': {
            title: 'Test 1: Valid Payment',
            content: `
                <div class="test-result-success">
                    <h3><i class="fas fa-check-circle"></i> Test Passed</h3>
                    <p><strong>Test SQL:</strong></p>
                    <pre class="code-block">INSERT INTO PAYMENT (
    TransactionCode, Amount, PaymentMethod, 
    PassengerID, TicketNumber, Status
) VALUES (
    'TXN_TEST001', 50.00, 'UPI', 1, 1, 'Completed'
);</pre>
                    <p><strong>Result:</strong> ✅ Query OK, 1 row affected</p>
                    <p>Payment successfully inserted with ticket reference.</p>
                </div>
            `
        },
        'payment-invalid': {
            title: 'Test 2: Both Ticket & Pass',
            content: `
                <div class="test-result-error">
                    <h3><i class="fas fa-times-circle"></i> Test Failed (Expected)</h3>
                    <p><strong>Test SQL:</strong></p>
                    <pre class="code-block">INSERT INTO PAYMENT (
    TransactionCode, Amount, PaymentMethod,
    PassengerID, TicketNumber, PassID, Status
) VALUES (
    'TXN_TEST002', 50.00, 'UPI', 1, 1, 1, 'Completed'
);</pre>
                    <p><strong>Error:</strong> ❌ Payment cannot be associated with both a Ticket and a Pass</p>
                    <p>Trigger correctly prevented invalid payment entry.</p>
                </div>
            `
        },
        'payment-no-ref': {
            title: 'Test 3: No Reference',
            content: `
                <div class="test-result-error">
                    <h3><i class="fas fa-times-circle"></i> Test Failed (Expected)</h3>
                    <p><strong>Test SQL:</strong></p>
                    <pre class="code-block">INSERT INTO PAYMENT (
    TransactionCode, Amount, PaymentMethod,
    PassengerID, Status
) VALUES (
    'TXN_TEST003', 50.00, 'UPI', 1, 'Completed'
);</pre>
                    <p><strong>Error:</strong> ❌ Payment must be associated with either a Ticket or a Pass</p>
                    <p>Trigger correctly enforced reference requirement.</p>
                </div>
            `
        },
        'payment-refund': {
            title: 'Test 4: Excessive Refund',
            content: `
                <div class="test-result-error">
                    <h3><i class="fas fa-times-circle"></i> Test Failed (Expected)</h3>
                    <p><strong>Test SQL:</strong></p>
                    <pre class="code-block">INSERT INTO PAYMENT (
    TransactionCode, Amount, PaymentMethod,
    PassengerID, TicketNumber, RefundAmount, Status
) VALUES (
    'TXN_TEST004', 50.00, 'UPI', 1, 1, 60.00, 'Refunded'
);</pre>
                    <p><strong>Error:</strong> ❌ Refund amount cannot exceed original amount</p>
                    <p>Trigger correctly validated refund constraint.</p>
                </div>
            `
        },
        'pass-future': {
            title: 'Test 1: Future Pass',
            content: `
                <div class="test-result-success">
                    <h3><i class="fas fa-check-circle"></i> Test Passed</h3>
                    <p><strong>Test SQL:</strong></p>
                    <pre class="code-block">INSERT INTO PASS (
    PassCode, PassType, StartDate, EndDate, 
    Price, PassengerID
) VALUES (
    'PASS_TEST001', 'Monthly', '2025-12-01', '2025-12-31',
    1500.00, 1
);</pre>
                    <p><strong>Result:</strong> ✅ Query OK, PassStatus automatically set to 'Active'</p>
                    <p>Trigger correctly identified future pass and set status to Active.</p>
                </div>
            `
        },
        'pass-expired': {
            title: 'Test 2: Expired Pass',
            content: `
                <div class="test-result-success">
                    <h3><i class="fas fa-check-circle"></i> Test Passed</h3>
                    <p><strong>Test SQL:</strong></p>
                    <pre class="code-block">INSERT INTO PASS (
    PassCode, PassType, StartDate, EndDate,
    Price, PassengerID
) VALUES (
    'PASS_TEST002', 'Daily', '2024-01-01', '2024-01-02',
    100.00, 2
);</pre>
                    <p><strong>Result:</strong> ✅ Query OK, PassStatus automatically set to 'Expired'</p>
                    <p>Trigger correctly identified expired pass and set status to Expired.</p>
                </div>
            `
        },
        'pass-invalid': {
            title: 'Test 3: Invalid Dates',
            content: `
                <div class="test-result-error">
                    <h3><i class="fas fa-times-circle"></i> Test Failed (Expected)</h3>
                    <p><strong>Test SQL:</strong></p>
                    <pre class="code-block">INSERT INTO PASS (
    PassCode, PassType, StartDate, EndDate,
    Price, PassengerID
) VALUES (
    'PASS_TEST003', 'Monthly', '2024-02-28', '2024-02-01',
    1500.00, 3
);</pre>
                    <p><strong>Error:</strong> ❌ Pass end date must be after start date</p>
                    <p>Trigger correctly prevented invalid date range.</p>
                </div>
            `
        }
    };
    
    const test = testResults[testType];
    if (test) {
        title.textContent = test.title;
        content.innerHTML = test.content;
        modal.classList.add('active');
    }
}

function closeTestModal() {
    document.getElementById('testResultModal').classList.remove('active');
}

window.onclick = function(event) {
    const modal = document.getElementById('testResultModal');
    if (event.target === modal) closeTestModal();
}
