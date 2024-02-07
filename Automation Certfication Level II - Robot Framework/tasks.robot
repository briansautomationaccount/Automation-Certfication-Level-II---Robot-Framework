*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.Windows
Library           RPA.Desktop
Library           OperatingSystem
Library           RPA.FileSystem
Library           RPA.Archive

*** Variables ***
${error_locator}=    //input[@class='alert alert-danger']

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Create Zip from PDFs
    Cleanup temporary PDF directory
    

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Close the annoying modal
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    has_header=True
    FOR    ${orders}    IN    @{orders}
        Fill the form    ${orders}
    END

Close the annoying modal
    Click Button    OK

Handle error alert
    ${error_locator}=               Get Element Count                                             //div[@class='alert alert-danger']
    WHILE    ${error_locator} > 0
        Click Element When Clickable                //*[@id="order"]    timeout=10s
        ${error_locator}=            Get Element Count                                          //div[@class='alert alert-danger']
    END
    

Fill the form
    [Arguments]    ${orders}
    
    Select From List By Value       id:head                                                       ${orders}[Head]
    Select Radio Button             body                                                          ${orders}[Body]
    Input Text                      //input[@placeholder='Enter the part number for the legs']    ${orders}[Legs]
    Input Text                      id:address                                                    ${orders}[Address]
    Click Element When Clickable    //*[@id="order"]                                              timeout=10s
    Handle error alert
    Embed the robot screenshot to the receipt PDF file    ${OUTPUT_DIR}${/}receipts${/}${orders}[Order number].png    ${OUTPUT_DIR}${/}receipts${/}${orders}[Order number].pdf  
    Click Button                 Order another robot
    Close the annoying modal

Embed the robot screenshot to the receipt PDF file    
    [Arguments]    ${screenshot}    ${pdf}

    Wait Until Element Is Visible    id:receipt

    Capture Element Screenshot    id:receipt    ${screenshot}
    ${order_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_receipt_html}    ${pdf}
    Log    ${pdf}
    Open Pdf    ${pdf}

    ${files}=    Create List    ${pdf}    ${screenshot}    
    
    Add Files To Pdf    ${files}    ${pdf}
    Close Pdf    ${pdf}
    Run Keyword    Remove File    ${screenshot}

Create Zip from PDFs
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/Receipt_PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}receipts
    ...    ${zip_file_name}

Cleanup temporary PDF directory
    Remove Directory    ${OUTPUT_DIR}${/}receipts    True
    
