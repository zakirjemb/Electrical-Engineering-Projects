function success = send_to_firestore(projectId, firestoreCollection, documentId, data)
success = false;
max_retries = 5;
initial_retry_delay_sec = 2;
url = sprintf('https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/%s/%s', projectId, firestoreCollection, documentId);
processed_data = data;
fields = fieldnames(processed_data);
for i = 1:length(fields)
    fieldName = fields{i};
    currentValue = processed_data.(fieldName);
    if isnumeric(currentValue)
        if isnan(currentValue)
            processed_data.(fieldName) = 0;
        elseif isinf(currentValue)
            processed_data.(fieldName) = 0;
        end
    elseif isempty(currentValue) && ~ischar(currentValue) && ~islogical(currentValue)
        processed_data.(fieldName) = 0;
    end
end
try
    firestore_fields = struct();
    fieldNames = fieldnames(processed_data);
    for k = 1:length(fieldNames)
        fName = fieldNames{k};
        fValue = processed_data.(fName);
        firestore_fields.(fName) = mapMatlabValueToFirestoreType(fValue);
    end
    jsonBody = jsonencode(struct('fields', firestore_fields), 'PrettyPrint', true);
catch ME
    warning('Failed to encode data to JSON: %s', ME.message);
    return;
end
options = weboptions('MediaType', 'application/json', 'RequestMethod', 'patch', 'Timeout', 30);
current_retry_delay = initial_retry_delay_sec;
for attempt = 1:max_retries
    try
        fprintf('  Attempting to send to Firestore (Attempt %d/%d)...\n', attempt, max_retries);
        response = webwrite(url, jsonBody, options);
        if isstruct(response) && isfield(response, 'name') && contains(response.name, documentId)
            fprintf('-> Fault data SENT to Firestore successfully! Document ID: %s.\n', documentId);
            success = true;
            break;
        else
            warning('Firestore upload completed, but response was unexpected for document ID: %s. Response: %s', documentId, jsonencode(response));
            success = true;
            break;
        end
    catch ME
        fprintf(2, '-> ERROR: Failed to send data to Firestore (Attempt %d/%d): %s\n', attempt, max_retries, ME.message);
        if attempt < max_retries
            fprintf('    Retrying in %d seconds...\n', current_retry_delay);
            pause(current_retry_delay);
            current_retry_delay = current_retry_delay * 2;
        else
            fprintf(2, '    Max retries reached. Firestore data send failed for Document ID: %s.\n', documentId);
            fprintf(2, '    Ensure:\n');
            fprintf(2, '    - Internet connection is active.\n');
            fprintf(2, '    - Google Cloud Project ID (%s) and Firestore Collection Name (%s) are correct.\n', projectId, firestoreCollection);
            fprintf(2, '    - Your Firestore security rules allow the necessary write access.\n');
            success = false;
        end
    end
end
end
function firestoreFields = createFirestoreFieldsRecursive(matlabData)
    firestoreFields = struct();
    if isstruct(matlabData)
        fieldNames = fieldnames(matlabData);
        for k = 1:length(fieldNames)
            fName = fieldNames{k};
            fValue = matlabData.(fName);
            firestoreFields.(fName) = mapMatlabValueToFirestoreType(fValue);
        end
    elseif ismap(matlabData)
        keys = matlabData.keys;
        for k = 1:length(keys)
            fName = keys{k};
            fValue = matlabData(fName);
            firestoreFields.(fName) = mapMatlabValueToFirestoreType(fValue);
        end
    else
        warning('Unhandled data type in recursive Firestore field creation: %s', class(matlabData));
        try
            firestoreFields = struct('stringValue', jsonencode(matlabData));
        catch
            firestoreFields = struct('stringValue', 'UNSUPPORTED_DATA_TYPE_ERROR');
        end
    end
end
function firestoreValueStruct = mapMatlabValueToFirestoreType(value)
    if ischar(value)
        firestoreValueStruct = struct('stringValue', value);
    elseif isnumeric(value)
        if isnan(value)
            firestoreValueStruct = struct('nullValue', 'NULL_VALUE');
        elseif isinf(value)
            firestoreValueStruct = struct('doubleValue', 0);
        elseif isinteger(value) || (value == floor(value) && abs(value) <= 2^53)
            firestoreValueStruct = struct('integerValue', num2str(value));
        else
            firestoreValueStruct = struct('doubleValue', value);
        end
    elseif islogical(value)
        firestoreValueStruct = struct('booleanValue', value);
    elseif isstruct(value)
        firestoreValueStruct = struct('mapValue', struct('fields', createFirestoreFieldsRecursive(value)));
    elseif iscell(value)
        arrayValues = cell(size(value));
        for i = 1:numel(value)
            arrayValues{i} = mapMatlabValueToFirestoreType(value{i});
        end
        firestoreValueStruct = struct('arrayValue', struct('values', arrayValues));
    else
        warning('Unhandled data type for Firestore conversion: %s. Attempting string conversion.', class(value));
        try
            firestoreValueStruct = struct('stringValue', jsonencode(value));
        catch
            firestoreValueStruct = struct('stringValue', 'UNSUPPORTED_TYPE_CONVERSION_ERROR');
        end
    end
end
