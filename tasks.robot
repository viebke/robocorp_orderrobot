*** Settings ***
Documentation       Template robot main suite.

Library             RPA.HTTP
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.Desktop
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.RobotLogListener
Library             RPA.Robocorp.Vault
Library             OperatingSystem
Library             RPA.Dialogs


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${secret}=    Get Secret    urls
    Open the robot order website    ${secret}[robotorder]
    ${orders}=    Get orders    ${secret}[ordersurl]

    Remove orders

    FOR    ${row}    IN    @{orders}
        TRY
            Close the annoying modal
            Fill the form    ${row}
            Preview the robot
            Submit the order
            ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
            ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
            Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
            Log    "added bot"
        EXCEPT    AS    ${error_message}
            Log    ${error_message}
        FINALLY
            Go to order another robot    ${secret}[robotorder]
        END
    END
    Create a ZIP file of the receipts
    Show success dialog


*** Keywords ***
Open the robot order website
    [Arguments]    ${url}
    Open Available Browser    ${url}

Get orders
    [Arguments]    ${url}
    Download
    ...    ${url}
    ...    overwrite=True
    ...    target_file=${OUTPUT_DIR}${/}orders.csv    overwrite=True
    ${table}=    Read Table From Csv    ${OUTPUT_DIR}${/}orders.csv    header=True
    Log    ${table}
    RETURN    ${table}

Close the annoying modal
    Click Button    css:button.btn.btn-dark

Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Click Element    id:id-body-${row}[Body]
    Input Text    xpath://input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    name:address    ${row}[Address]

Preview the robot
    Click Element    id:preview

Submit the order
    Wait Until Keyword Succeeds    3x    1s    Click Element    id:order

Store the receipt as a PDF file
    [Arguments]    ${ordernumber}
    Wait Until Element Is Visible    id:receipt
    ${html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${html}    ${OUTPUT_DIR}${/}orders${/}${ordernumber}.pdf
    RETURN    ${OUTPUT_DIR}${/}orders${/}${ordernumber}.pdf

Take a screenshot of the robot
    [Arguments]    ${ordernumber}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}orders${/}${ordernumber}.png
    RETURN    ${OUTPUT_DIR}${/}orders${/}${ordernumber}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Log    ${pdf}
    ${list}=    Create List    ${pdf}    ${screenshot}
    Add Files To Pdf    ${list}    ${pdf}

Go to order another robot
    [Arguments]    ${url}
    Go To    ${url}

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}Orders.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}orders${/}
    ...    ${zip_file_name}

Remove orders
    Remove Directory    ${OUTPUT_DIR}${/}orders    recursive=True

Show success dialog
    Add icon    Success
    Add heading    Your orders have been processed
    Add files    ${OUTPUT_DIR}${/}Orders.zip
    Run dialog    title=Success
