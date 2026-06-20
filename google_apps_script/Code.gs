/**
 * Motracker — Google Apps Script Backend
 * 
 * This script turns your Google Sheet into a free REST API.
 * Deploy as a Web App and use the URL in your Flutter app.
 * 
 * Sheet Structure:
 * - Sheet "Transactions": id | date | type | category | amount | note | createdAt | userEmail
 * - Sheet "Budgets": id | category | limit | month | userEmail
 * - Sheet "Recurring": id | amount | type | category | note | frequency | startDate | endDate | isActive | userEmail
 */

// ============================================
// GET Handler — Fetch data
// ============================================
function doGet(e) {
  try {
    const params = e.parameter;
    const action = params.action || 'getTransactions';
    const userEmail = params.email;

    if (!userEmail) {
      return jsonResponse({ error: 'Email is required' }, 400);
    }

    const ss = SpreadsheetApp.getActiveSpreadsheet();

    switch (action) {
      case 'getTransactions':
        return jsonResponse(getSheetData(ss, 'Transactions', userEmail));
      case 'getBudgets':
        return jsonResponse(getSheetData(ss, 'Budgets', userEmail));
      case 'getRecurring':
        return jsonResponse(getSheetData(ss, 'Recurring', userEmail));
      case 'getAll':
        return jsonResponse({
          transactions: getSheetData(ss, 'Transactions', userEmail),
          budgets: getSheetData(ss, 'Budgets', userEmail),
          recurring: getSheetData(ss, 'Recurring', userEmail),
        });
      case 'addTransaction':
        if (params.data) {
          const itemData = JSON.parse(params.data);
          return jsonResponse(addTransaction(ss, itemData, userEmail));
        }
        return jsonResponse({ error: 'No data provided' }, 400);
      default:
        return jsonResponse({ error: 'Unknown action: ' + action }, 400);
    }
  } catch (error) {
    return jsonResponse({ error: error.message }, 500);
  }
}

// ============================================
// POST Handler — Create, Update, Delete
// ============================================
function doPost(e) {
  try {
    const body = JSON.parse(e.postData.contents);
    const action = body.action;
    const userEmail = body.email;

    if (!userEmail) {
      return jsonResponse({ error: 'Email is required' }, 400);
    }

    const ss = SpreadsheetApp.getActiveSpreadsheet();

    switch (action) {
      case 'addTransaction':
        return jsonResponse(addTransaction(ss, body.data, userEmail));
      case 'updateTransaction':
        return jsonResponse(updateRow(ss, 'Transactions', body.data, userEmail));
      case 'deleteTransaction':
        return jsonResponse(deleteRow(ss, 'Transactions', body.id, userEmail));

      case 'addBudget':
        return jsonResponse(addBudget(ss, body.data, userEmail));
      case 'updateBudget':
        return jsonResponse(updateRow(ss, 'Budgets', body.data, userEmail));
      case 'deleteBudget':
        return jsonResponse(deleteRow(ss, 'Budgets', body.id, userEmail));

      case 'addRecurring':
        return jsonResponse(addRecurring(ss, body.data, userEmail));
      case 'updateRecurring':
        return jsonResponse(updateRow(ss, 'Recurring', body.data, userEmail));
      case 'deleteRecurring':
        return jsonResponse(deleteRow(ss, 'Recurring', body.id, userEmail));

      case 'syncAll':
        return jsonResponse(syncAll(ss, body.data, userEmail));

      default:
        return jsonResponse({ error: 'Unknown action: ' + action }, 400);
    }
  } catch (error) {
    return jsonResponse({ error: error.message }, 500);
  }
}

// ============================================
// Data Operations
// ============================================

function addTransaction(ss, data, email) {
  const sheet = getOrCreateSheet(ss, 'Transactions',
    ['id', 'date', 'type', 'category', 'amount', 'note', 'createdAt', 'userEmail']);

  sheet.appendRow([
    data.id,
    data.date,
    data.type,
    data.category,
    data.amount,
    data.note || '',
    data.createdAt || new Date().toISOString(),
    email
  ]);

  return { status: 'success', id: data.id };
}

function addBudget(ss, data, email) {
  const sheet = getOrCreateSheet(ss, 'Budgets',
    ['id', 'category', 'limit', 'month', 'userEmail']);

  sheet.appendRow([
    data.id,
    data.category,
    data.limit,
    data.month,
    email
  ]);

  return { status: 'success', id: data.id };
}

function addRecurring(ss, data, email) {
  const sheet = getOrCreateSheet(ss, 'Recurring',
    ['id', 'amount', 'type', 'category', 'note', 'frequency', 'startDate', 'endDate', 'isActive', 'userEmail']);

  sheet.appendRow([
    data.id,
    data.amount,
    data.type,
    data.category,
    data.note || '',
    data.frequency,
    data.startDate,
    data.endDate || '',
    data.isActive !== false,
    email
  ]);

  return { status: 'success', id: data.id };
}

function updateRow(ss, sheetName, data, email) {
  const sheet = ss.getSheetByName(sheetName);
  if (!sheet) return { error: 'Sheet not found: ' + sheetName };

  const allData = sheet.getDataRange().getValues();
  const headers = allData[0];
  const idCol = headers.indexOf('id');
  const emailCol = headers.indexOf('userEmail');

  for (let i = 1; i < allData.length; i++) {
    if (allData[i][idCol] === data.id && allData[i][emailCol] === email) {
      // Update each column
      headers.forEach((header, colIdx) => {
        if (header !== 'id' && header !== 'userEmail' && data[header] !== undefined) {
          sheet.getRange(i + 1, colIdx + 1).setValue(data[header]);
        }
      });
      return { status: 'success', id: data.id };
    }
  }

  return { error: 'Row not found with id: ' + data.id };
}

function deleteRow(ss, sheetName, id, email) {
  const sheet = ss.getSheetByName(sheetName);
  if (!sheet) return { error: 'Sheet not found: ' + sheetName };

  const allData = sheet.getDataRange().getValues();
  const headers = allData[0];
  const idCol = headers.indexOf('id');
  const emailCol = headers.indexOf('userEmail');

  for (let i = allData.length - 1; i >= 1; i--) {
    if (allData[i][idCol] === id && allData[i][emailCol] === email) {
      sheet.deleteRow(i + 1);
      return { status: 'success', id: id };
    }
  }

  return { error: 'Row not found with id: ' + id };
}

function syncAll(ss, data, email) {
  const results = { transactions: 0, budgets: 0, recurring: 0 };

  if (data.transactions && data.transactions.length > 0) {
    const sheet = getOrCreateSheet(ss, 'Transactions',
      ['id', 'date', 'type', 'category', 'amount', 'note', 'createdAt', 'userEmail']);
    const existingIds = getExistingIds(sheet, email);

    data.transactions.forEach(t => {
      if (!existingIds.has(t.id)) {
        sheet.appendRow([t.id, t.date, t.type, t.category, t.amount, t.note || '', t.createdAt || new Date().toISOString(), email]);
        results.transactions++;
      }
    });
  }

  if (data.budgets && data.budgets.length > 0) {
    const sheet = getOrCreateSheet(ss, 'Budgets',
      ['id', 'category', 'limit', 'month', 'userEmail']);
    const existingIds = getExistingIds(sheet, email);

    data.budgets.forEach(b => {
      if (!existingIds.has(b.id)) {
        sheet.appendRow([b.id, b.category, b.limit, b.month, email]);
        results.budgets++;
      }
    });
  }

  if (data.recurring && data.recurring.length > 0) {
    const sheet = getOrCreateSheet(ss, 'Recurring',
      ['id', 'amount', 'type', 'category', 'note', 'frequency', 'startDate', 'endDate', 'isActive', 'userEmail']);
    const existingIds = getExistingIds(sheet, email);

    data.recurring.forEach(r => {
      if (!existingIds.has(r.id)) {
        sheet.appendRow([r.id, r.amount, r.type, r.category, r.note || '', r.frequency, r.startDate, r.endDate || '', r.isActive !== false, email]);
        results.recurring++;
      }
    });
  }

  return { status: 'success', synced: results };
}

// ============================================
// Helper Functions
// ============================================

function getSheetData(ss, sheetName, email) {
  const sheet = ss.getSheetByName(sheetName);
  if (!sheet) return [];

  const allData = sheet.getDataRange().getValues();
  if (allData.length <= 1) return [];

  const headers = allData[0];
  const emailCol = headers.indexOf('userEmail');

  return allData.slice(1)
    .filter(row => row[emailCol] === email)
    .map(row => {
      const obj = {};
      headers.forEach((header, idx) => {
        if (header !== 'userEmail') {
          obj[header] = row[idx];
        }
      });
      return obj;
    });
}

function getOrCreateSheet(ss, sheetName, headers) {
  let sheet = ss.getSheetByName(sheetName);
  if (!sheet) {
    sheet = ss.insertSheet(sheetName);
    sheet.appendRow(headers);
    // Bold headers
    sheet.getRange(1, 1, 1, headers.length).setFontWeight('bold');
    // Freeze header row
    sheet.setFrozenRows(1);
  }
  return sheet;
}

function getExistingIds(sheet, email) {
  const ids = new Set();
  const allData = sheet.getDataRange().getValues();
  if (allData.length <= 1) return ids;

  const headers = allData[0];
  const idCol = headers.indexOf('id');
  const emailCol = headers.indexOf('userEmail');

  allData.slice(1).forEach(row => {
    if (row[emailCol] === email) {
      ids.add(row[idCol]);
    }
  });

  return ids;
}

function jsonResponse(data, statusCode) {
  return ContentService
    .createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
