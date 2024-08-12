       IDENTIFICATION DIVISION.
       PROGRAM-ID. InventoryManagement.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT InventoryFile ASSIGN TO 'INVENTORY.DAT'
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS InventoryID
               FILE STATUS IS WS-FILE-STATUS.
           SELECT ExportFile ASSIGN TO 'EXPORT.DAT'
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT ImportFile ASSIGN TO 'IMPORT.DAT'
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT AuditFile ASSIGN TO 'AUDIT.LOG'
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD InventoryFile.
       01 InventoryRecord.
           05 InventoryID              PIC X(10).
           05 ItemName                 PIC X(50).
           05 QuantityOnHand           PIC 9(5).
           05 ReorderLevel             PIC 9(5).
           05 Price                    PIC 9(5)V99.
           05 LastUpdatedDate          PIC X(20).

       FD ExportFile.
       01 ExportRecord.
           05 ExportData PIC X(70).

       FD ImportFile.
       01 ImportRecord.
           05 ImportData PIC X(70).

       FD AuditFile.
       01 AuditRecord.
           05 AuditData PIC X(70).

       WORKING-STORAGE SECTION.
       01 WS-FILE-STATUS               PIC XX.
       01 WS-EOF                       PIC X VALUE 'N'.
       01 WS-OPTION                    PIC 9 VALUE 0.
       01 WS-RECORD-FOUND              PIC X VALUE 'N'.
       01 WS-SEARCH-NAME               PIC X(50).
       01 WS-TOTAL-VALUE               PIC 9(10)V99 VALUE 0.
       01 WS-ITEM-COUNT                PIC 9(5) VALUE 0.
       01 WS-LOW-STOCK-COUNT           PIC 9(5) VALUE 0.
       01 WS-PERCENTAGE                PIC 9(3)V99 VALUE 0.
       01 WS-LAST-UPDATED-DATE         PIC X(20).
       01 WS-UPDATE-LOG                PIC X(70).

       PROCEDURE DIVISION.
           OPEN I-O InventoryFile
           OPEN OUTPUT AuditFile
           PERFORM UNTIL WS-EOF = 'Y'
               DISPLAY '1. Add Item'
               DISPLAY '2. Update Item'
               DISPLAY '3. View Inventory'
               DISPLAY '4. Delete Item'
               DISPLAY '5. Generate Reorder Report'
               DISPLAY '6. Search Item by Name'
               DISPLAY '7. Calculate Total Inventory Value'
               DISPLAY '8. Generate Low Stock Alert'
               DISPLAY '9. Generate Inventory Summary Report'
               DISPLAY '10. Update Item Price by Percentage'
               DISPLAY '11. Export Inventory Data'
               DISPLAY '12. Import Inventory Data'
               DISPLAY '13. Exit'
               ACCEPT WS-OPTION
               EVALUATE WS-OPTION
                   WHEN 1
                       PERFORM AddItem
                   WHEN 2
                       PERFORM UpdateItem
                   WHEN 3
                       PERFORM ViewInventory
                   WHEN 4
                       PERFORM DeleteItem
                   WHEN 5
                       PERFORM GenerateReorderReport
                   WHEN 6
                       PERFORM SearchItemByName
                   WHEN 7
                       PERFORM CalculateTotalInventoryValue
                   WHEN 8
                       PERFORM GenerateLowStockAlert
                   WHEN 9
                       PERFORM GenerateInventorySummaryReport
                   WHEN 10
                       PERFORM UpdateItemPriceByPercentage
                   WHEN 11
                       PERFORM ExportInventoryData
                   WHEN 12
                       PERFORM ImportInventoryData
                   WHEN 13
                       MOVE 'Y' TO WS-EOF
                   WHEN OTHER
                       DISPLAY 'Invalid Option'
               END-EVALUATE
           END-PERFORM.
           CLOSE InventoryFile
           CLOSE AuditFile
           STOP RUN.

       AddItem SECTION.
           DISPLAY 'Enter Inventory ID:'
           ACCEPT InventoryID
           DISPLAY 'Enter Item Name:'
           ACCEPT ItemName
           DISPLAY 'Enter Quantity on Hand:'
           ACCEPT QuantityOnHand
           DISPLAY 'Enter Reorder Level:'
           ACCEPT ReorderLevel
           DISPLAY 'Enter Price:'
           ACCEPT Price
           MOVE FUNCTION CURRENT-DATE TO LastUpdatedDate
           WRITE InventoryRecord
           MOVE 'Added Item ' TO WS-UPDATE-LOG
           STRING InventoryID DELIMITED BY SPACE
                  ItemName DELIMITED BY SPACE
                  QuantityOnHand DELIMITED BY SPACE
                  ReorderLevel DELIMITED BY SPACE
                  Price DELIMITED BY SPACE
                  LastUpdatedDate DELIMITED BY SPACE
                  INTO WS-UPDATE-LOG
           WRITE AuditRecord FROM WS-UPDATE-LOG
           DISPLAY 'Item Added Successfully'
           EXIT.

       UpdateItem SECTION.
           DISPLAY 'Enter Inventory ID to Update:'
           ACCEPT InventoryID
           READ InventoryFile
               INVALID KEY DISPLAY 'Item Not Found'
               NOT INVALID KEY
                   DISPLAY 'Enter New Quantity on Hand:'
                   ACCEPT QuantityOnHand
                   DISPLAY 'Enter New Reorder Level:'
                   ACCEPT ReorderLevel
                   DISPLAY 'Enter New Price:'
                   ACCEPT Price
                   MOVE FUNCTION CURRENT-DATE TO LastUpdatedDate
                   REWRITE InventoryRecord
                   MOVE 'Updated Item ' TO WS-UPDATE-LOG
                   STRING InventoryID DELIMITED BY SPACE
                          QuantityOnHand DELIMITED BY SPACE
                          ReorderLevel DELIMITED BY SPACE
                          Price DELIMITED BY SPACE
                          LastUpdatedDate DELIMITED BY SPACE
                          INTO WS-UPDATE-LOG
                   WRITE AuditRecord FROM WS-UPDATE-LOG
                   DISPLAY 'Item Updated Successfully'
           EXIT.

       ViewInventory SECTION.
           START InventoryFile KEY IS GREATER THAN OR EQUAL TO SPACES
           PERFORM UNTIL WS-FILE-STATUS = '10'
               READ InventoryFile NEXT RECORD
                   AT END MOVE 'Y' TO WS-EOF
                   NOT AT END
                       DISPLAY 'ID: ' InventoryID
                       DISPLAY 'Name: ' ItemName
                       DISPLAY 'Quantity: ' QuantityOnHand
                       DISPLAY 'Reorder Level: ' ReorderLevel
                       DISPLAY 'Price: ' Price
                       DISPLAY 'Last Updated: ' LastUpdatedDate
                       DISPLAY '-----------------------'
           END-PERFORM
           EXIT.

       DeleteItem SECTION.
           DISPLAY 'Enter Inventory ID to Delete:'
           ACCEPT InventoryID
           READ InventoryFile
               INVALID KEY DISPLAY 'Item Not Found'
               NOT INVALID KEY
                   DELETE InventoryFile
                   MOVE 'Deleted Item ' TO WS-UPDATE-LOG
                   STRING InventoryID DELIMITED BY SPACE
                          INTO WS-UPDATE-LOG
                   WRITE AuditRecord FROM WS-UPDATE-LOG
                   DISPLAY 'Item Deleted Successfully'
           EXIT.

       GenerateReorderReport SECTION.
           DISPLAY 'Reorder Report:'
           DISPLAY '-----------------------'
           START InventoryFile KEY IS GREATER THAN OR EQUAL TO SPACES
           PERFORM UNTIL WS-FILE-STATUS = '10'
               READ InventoryFile NEXT RECORD
                   AT END MOVE 'Y' TO WS-EOF
                   NOT AT END
                       IF QuantityOnHand < ReorderLevel
                           DISPLAY 'ID: ' InventoryID
                           DISPLAY 'Name: ' ItemName
                           DISPLAY 'Quantity on Hand: ' QuantityOnHand
                           DISPLAY 'Reorder Level: ' ReorderLevel
                           DISPLAY '-----------------------'
                       END-IF
           END-PERFORM
           EXIT.

       SearchItemByName SECTION.
           DISPLAY 'Enter Item Name to Search:'
           ACCEPT WS-SEARCH-NAME
           START InventoryFile KEY IS GREATER THAN OR EQUAL TO SPACES
           PERFORM UNTIL WS-FILE-STATUS = '10'
               READ InventoryFile NEXT RECORD
                   AT END MOVE 'Y' TO WS-EOF
                   NOT AT END
                       IF WS-SEARCH-NAME = ItemName
                           DISPLAY 'ID: ' InventoryID
                           DISPLAY 'Name: ' ItemName
                           DISPLAY 'Quantity on Hand: ' QuantityOnHand
                           DISPLAY 'Reorder Level: ' ReorderLevel
                           DISPLAY 'Price: ' Price
                           DISPLAY 'Last Updated: ' LastUpdatedDate
                           DISPLAY '-----------------------'
                       END-IF
           END-PERFORM
           EXIT.

       CalculateTotalInventoryValue SECTION.
           MOVE 0 TO WS-TOTAL-VALUE
           START InventoryFile KEY IS GREATER THAN OR EQUAL TO SPACES
           PERFORM UNTIL WS-FILE-STATUS = '10'
               READ InventoryFile NEXT RECORD
                   AT END MOVE 'Y' TO WS-EOF
                   NOT AT END
                       COMPUTE WS-TOTAL-VALUE = WS-TOTAL-VALUE + (QuantityOnHand * Price)
           END-PERFORM
           DISPLAY 'Total Inventory Value: ' WS-TOTAL-VALUE
           EXIT.

       GenerateLowStockAlert SECTION.
           DISPLAY 'Low Stock Alert:'
           DISPLAY '-----------------------'
           START InventoryFile KEY IS GREATER THAN OR EQUAL TO SPACES
           PERFORM UNTIL WS-FILE-STATUS = '10'
               READ InventoryFile NEXT RECORD
                   AT END MOVE 'Y' TO WS-EOF
                   NOT AT END
                       IF QuantityOnHand < ReorderLevel
                           DISPLAY 'ALERT: Item ' ItemName ' is below reorder level!'
                           DISPLAY 'Quantity on Hand: ' QuantityOnHand
                           DISPLAY 'Reorder Level: ' ReorderLevel
                           DISPLAY '-----------------------'
                       END-IF
           END-PERFORM
           EXIT.

       GenerateInventorySummaryReport SECTION.
           DISPLAY 'Inventory Summary Report:'
           DISPLAY '-----------------------'
           MOVE 0 TO WS-ITEM-COUNT
           MOVE 0 TO WS-LOW-STOCK-COUNT
           START InventoryFile KEY IS GREATER THAN OR EQUAL TO SPACES
           PERFORM UNTIL WS-FILE-STATUS = '10'
               READ InventoryFile NEXT RECORD
                   AT END MOVE 'Y' TO WS-EOF
                   NOT AT END
                       ADD 1 TO WS-ITEM-COUNT
                       IF QuantityOnHand < ReorderLevel
                           ADD 1 TO WS-LOW-STOCK-COUNT
                       END-IF
           END-PERFORM
           DISPLAY 'Total Items: ' WS-ITEM-COUNT
           DISPLAY 'Items Below Reorder Level: ' WS-LOW-STOCK-COUNT
           EXIT.

       UpdateItemPriceByPercentage SECTION.
           DISPLAY 'Enter Inventory ID to Update Price:'
           ACCEPT InventoryID
           DISPLAY 'Enter Percentage Increase/Decrease (e.g., 10 for 10%):'
           ACCEPT WS-PERCENTAGE
           READ InventoryFile
               INVALID KEY DISPLAY 'Item Not Found'
               NOT INVALID KEY
                   COMPUTE NewPrice = Price * (1 + (WS-PERCENTAGE / 100))
                   MOVE FUNCTION CURRENT-DATE TO LastUpdatedDate
                   REWRITE InventoryRecord
                   MOVE 'Updated Price for Item ' TO WS-UPDATE-LOG
                   STRING InventoryID DELIMITED BY SPACE
                          NewPrice DELIMITED BY SPACE
                          LastUpdatedDate DELIMITED BY SPACE
                          INTO WS-UPDATE-LOG
                   WRITE AuditRecord FROM WS-UPDATE-LOG
                   DISPLAY 'Price Updated Successfully to: ' NewPrice
           EXIT.

       ExportInventoryData SECTION.
           OPEN OUTPUT ExportFile
           START InventoryFile KEY IS GREATER THAN OR EQUAL TO SPACES
           PERFORM UNTIL WS-FILE-STATUS = '10'
               READ InventoryFile NEXT RECORD
                   AT END MOVE 'Y' TO WS-EOF
                   NOT AT END
                       STRING InventoryID DELIMITED BY SPACE
                              ItemName DELIMITED BY SPACE
                              QuantityOnHand DELIMITED BY SPACE
                              ReorderLevel DELIMITED BY SPACE
                              Price DELIMITED BY SPACE
                              LastUpdatedDate DELIMITED BY SPACE
                              INTO ExportData
                       WRITE ExportRecord FROM ExportData
           END-PERFORM
           CLOSE ExportFile
           DISPLAY 'Inventory Data Exported Successfully'
           EXIT.

       ImportInventoryData SECTION.
           OPEN INPUT ImportFile
           PERFORM UNTIL WS-FILE-STATUS = '10'
               READ ImportFile INTO ImportRecord
                   AT END MOVE 'Y' TO WS-EOF
                   NOT AT END
                       UNSTRING ImportData DELIMITED BY SPACE
                           INTO InventoryID
                                ItemName
                                QuantityOnHand
                                ReorderLevel
                                Price
                                LastUpdatedDate
                       WRITE InventoryRecord
           END-PERFORM
           CLOSE ImportFile
           DISPLAY 'Inventory Data Imported Successfully'
           EXIT.
