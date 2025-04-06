const properties = PropertiesService.getScriptProperties();

function appendToCsvFile(lineToAppend: string): void {
  const fileId = properties.getProperty("CSV_FILE_ID");
  if (fileId === null) {
    throw new Error("CSV file ID property is not defined");
  }
  const file = DriveApp.getFileById(fileId);

  let content = file.getBlob().getDataAsString();
  content += lineToAppend + "\n";
  file.setContent(content);
}

function doPost(
  e: GoogleAppsScript.Events.DoPost,
): GoogleAppsScript.Content.TextOutput {
  const { secret: providedSecret, line } = e.parameter;

  const apiSecret = properties.getProperty("API_SECRET");

  if (providedSecret !== apiSecret) {
    return ContentService
      .createTextOutput("Unauthorized")
      .setMimeType(ContentService.MimeType.TEXT);
  }

  appendToCsvFile(line);

  return ContentService
    .createTextOutput("OK")
    .setMimeType(ContentService.MimeType.TEXT);
}
