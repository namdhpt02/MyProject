
CREATE DATABASE QLCFCSHARP
GO
USE QLCFCSHARP
GO


-- Info user + account
-- Food category
-- Food
-- Tablelist
-- Bill
-- Bill Info


CREATE TABLE INFO
(
	
	ACCOUNT VARCHAR(30) PRIMARY KEY,
	PASSWORD VARCHAR(30) NOT NULL,
	NAME NVARCHAR(30) NOT NULL,
	SEX BIT NOT NULL DEFAULT 1, -- FEMALE 0, MALE 1
	AGE INT,
	PHONE CHAR(10) NOT NULL,
	ADDRESS NVARCHAR(30),
	TYPE INT NOT NULL DEFAULT 0 --  ADMIN 1
)


CREATE TABLE FOODCATEGORY
(
	ID INT IDENTITY PRIMARY KEY,
	NAME NVARCHAR(30) NOT NULL
)


CREATE TABLE FOOD
(
	ID INT IDENTITY PRIMARY KEY,
	NAME NVARCHAR(30) DEFAULT N'Chưa đặt tên',
	UNIT NVARCHAR(20) NOT NULL,
	PRICE FLOAT NOT NULL DEFAULT 0,
	TYPE INT NOT NULL,
	FOREIGN KEY (TYPE) REFERENCES dbo.FOODCATEGORY(ID)
)
CREATE TABLE TABLELIST
(
	ID INT IDENTITY PRIMARY KEY,
	STATUS INT NOT NULL DEFAULT 0, -- O NULL, 1 FULL
)
CREATE TABLE BILL
(
	ID INT IDENTITY PRIMARY KEY,
	TABLENUM INT NOT NULL,
	ACC VARCHAR(30) NOT NULL,
	TIMEINT DATETIME NOT NULL,
	TIMEOUT DATETIME,
	STATUS INT NOT NULL DEFAULT 0 ,
	DISCOUNT INT DEFAULT 0,
	Total FLOAT DEFAULT 0
	FOREIGN KEY (TABLENUM) REFERENCES dbo.TABLELIST(ID),
	FOREIGN KEY (ACC) REFERENCES dbo.INFO(ACCOUNT)
)

CREATE TABLE BILLINFO
(
	IDBILL INT NOT NULL,
	IDFOOD INT NOT NULL,
	AMOUNT INT NOT NULL DEFAULT 0
	PRIMARY KEY (IDBILL,IDFOOD)
	FOREIGN KEY (IDBILL) REFERENCES dbo.BILL(ID),
	FOREIGN KEY (IDFOOD) REFERENCES dbo.FOOD(ID)
)
go
CREATE FUNCTION ShowBillTable(@ID int) -- IDTable
RETURNS @Show TABLE (
					NameF nvarchar(30),
					Amount INT,
					Unit nvarchar(20),
					Price FLOAT)
AS
BEGIN
	DECLARE @IDB INT -- ID Bill
	SELECT TOP 1 @IDB= ID FROM dbo.BILL WHERE TABLENUM=@ID AND STATUS =0
	ORDER BY ID DESC
	INSERT INTO @Show
	SELECT NAME,AMOUNT,UNIT,PRICE
	FROM dbo.BILLINFO INNER JOIN dbo.FOOD ON FOOD.ID=IDFOOD
	WHERE IDBILL=@IDB
	RETURN
END
go
INSERT INTO dbo.INFO
        ( ACCOUNT ,
          PASSWORD ,
          NAME ,
          SEX ,
          AGE ,
          PHONE ,
          ADDRESS ,
          TYPE
        )
VALUES  ( 'admin' , -- ACCOUNT - varchar(30)
          'admin' , -- PASSWORD - varchar(30)
          N'Nam' , -- NAME - nvarchar(30)
          1 , -- SEX - bit
          21 , -- AGE - int
          '0963885507' , -- PHONE - char(10)
          N'Phú Thọ' , -- ADDRESS - nvarchar(30)
          3  -- TYPE - int
        )
INSERT into dbo.INFO
        ( ACCOUNT ,
          PASSWORD ,
          NAME ,
          SEX ,
          AGE ,
          PHONE ,
          ADDRESS ,
          TYPE
        )
VALUES  ( 'admin1' , -- ACCOUNT - varchar(30)
          'admin' , -- PASSWORD - varchar(30)
          N'Hồng' , -- NAME - nvarchar(30)
          0 , -- SEX - bit
          21 , -- AGE - int
          '0963885507' , -- PHONE - char(10)
          N'Phú Thọ' , -- ADDRESS - nvarchar(30)
          0  -- TYPE - int
        )


INSERT INTO dbo.FOODCATEGORY
        ( NAME )
VALUES  ( N'Nước uống'  -- NAME - nvarchar(30)
          )
INSERT INTO dbo.FOODCATEGORY
        ( NAME )
VALUES  ( N'Đồ ăn'  -- NAME - nvarchar(30)
          )



INSERT INTO dbo.FOOD VALUES  ( N'Cocacola',   N'Lon',  10000.0,1  )
INSERT INTO dbo.FOOD VALUES  ( N'Pepsi',   N'Lon',  10000.0,1  )
INSERT INTO dbo.FOOD VALUES  ( N'Caffe',   N'Cốc',  15000.0,1  )

INSERT INTO dbo.FOOD VALUES  ( N'Xoài dầm',   N'Đĩa',  20000.0,2 )
INSERT INTO dbo.FOOD VALUES  ( N'Khoai tây chiên',   N'Đĩa',  30000.0,2)
--DBCC CHECKIDENT (FOOD, RESEED, 0)
DECLARE @i int =0
WHILE @i<20
BEGIN
	INSERT INTO dbo.TABLELIST
	        ( STATUS )
	VALUES  ( 0  -- STATUS - int
	          )
			  SET @i = @i+1
END

go
CREATE PROC ADDFOOD(@IDT int,@NAME nvarchar(30),@AM INT,@ACC VARCHAR(30))
AS
BEGIN
	
	IF (NOT  EXISTS (SELECT * FROM dbo.BILL WHERE TABLENUM = @IDT AND STATUS=0 ))	
	INSERT INTO dbo.BILL VALUES  ( @IDT,   @ACC , GETDATE() ,   NULL , 0 ,   0  ,0 )

		DECLARE @IDB INT
		DECLARE @IDF INT
        SELECT @IDF=ID FROM dbo.FOOD WHERE NAME=@NAME
		SELECT @IDB=ID FROM dbo.BILL WHERE TABLENUM=@IDT AND STATUS=0
		IF(EXISTS(SELECT * FROM dbo.BILLINFO WHERE IDBILL=@IDB AND IDFOOD=@IDF))
		UPDATE dbo.BILLINFO SET AMOUNT=AMOUNT+@AM WHERE IDBILL=@IDB AND IDFOOD=@IDF
		else 			
		BEGIN
		INSERT INTO dbo.BILLINFO VALUES  ( @IDB,@IDF,@AM)
		UPDATE dbo.TABLELIST SET STATUS=1 WHERE ID=@IDT
		END
        
END

go
CREATE PROC AddBill(@IDB INT,@Acc VARCHAR(30),@Dis INT)
AS
BEGIN
	IF(NOT EXISTS (SELECT * FROM dbo.BILL WHERE TABLENUM=@IDB AND STATUS=0))
	INSERT INTO dbo.BILL
	VALUES  ( @IDB , -- TABLENUM - int
	          @Acc , -- ACC - varchar(30)
	          GETDATE() , -- TIMEINT - time
	          NULL , -- TIMEOUT - time
	          0 , -- STATUS - int
	          @Dis, -- DISCOUNT - int
			  0 -- Total float
	        )
END
go
CREATE TRIGGER UpdateSTT ON dbo.Bill
FOR INSERT 
AS 
BEGIN
		DECLARE @IDT INT
		SELECT @IDT = Inserted.TABLENUM FROM Inserted
		UPDATE dbo.TABLELIST SET STATUS=1 WHERE ID=@IDT
END
go
CREATE TRIGGER UpdateHD ON dbo.Bill
FOR UPDATE
AS
BEGIN
	DECLARE @IDT INT
	SELECT @IDT = Inserted.TABLENUM FROM Inserted
	UPDATE dbo.TABLELIST SET STATUS = 0 WHERE ID = @IDT
END
GO

CREATE PROC PAYBILL(@IDT int,@Total float,@Dis int)
as
BEGIN
	DECLARE @IDB INT
	DECLARE @STT INT
	SELECT TOP 1 @IDB=ID,@STT=STATUS FROM dbo.BILL WHERE TABLENUM=@IDT ORDER BY ID DESC
	IF(@STT=0)
	UPDATE dbo.BILL SET TIMEOUT=GETDATE(),STATUS=1,Total=@Total WHERE ID=@IDB
end

EXEC dbo.ADDFOOD @IDT = 8, -- int
    @NAME = N'Pepsi', -- nvarchar(30)
    @AM = 2, -- int
    @ACC = 'admin1' -- varchar(30)


go
CREATE PROC GetListBillByDateAndPage(@checkIn DATETIME, @checkOut DATETIME, @page int)
AS 
BEGIN
	DECLARE @pageRows INT = 10
	DECLARE @selectRows INT = @pageRows
	DECLARE @exceptRows INT = (@page - 1) * @pageRows
	
	;WITH BillShow AS( SELECT ID, CONCAT(N'Bàn ',TABLENUM) AS [Tên bàn], Total AS [Tổng tiền], 
	TIMEINT AS [Ngày vào], TIMEOUT AS [Ngày ra], DISCOUNT AS [Giảm giá]
	FROM dbo.Bill
	WHERE TIMEINT >= @checkIn AND TIMEOUT <= @checkOut AND STATUS = 1)
	SELECT TOP (@selectRows) * FROM BillShow WHERE ID NOT IN (SELECT TOP (@exceptRows) ID FROM BillShow)
END

EXEC dbo.GetListBillByDateAndPage @checkIn = '29-04-2019 00:00:00', @checkOut = '30-04-2019 23:59:59',   @page = 2
EXEC dbo.GetListBillByDateAndPage @checkIn = '2019-04-30 15:50:38', -- datetime
    @checkOut = '2019-04-30 15:50:38', -- datetime
    @page = 0 -- int
go
CREATE PROC SUMTOTAL(@date1 datetime,@date2 datetime)
AS
BEGIN
	SELECT SUM(Total)
	FROM dbo.BILL
	WHERE TIMEINT>=@date1 AND TIMEOUT<=@date2

END

EXEC dbo.SUMTOTAL @date1 = '2019-04-29 02:42:06', -- datetime
    @date2 = '2019-05-01 02:42:06' -- datetime


go
CREATE function hienthiban(@account varchar(30))
returns @bang table(
					NAME nvarchar(30),
					SEX nvarchar(5),
					AGE int,
					PHONE nvarchar(30),
					ADDRESS nvarchar(30)
					)
as
	begin
		insert into @bang
			select NAME,
			case
			when SEX=0 then N'Nữ'
			else N'Nam'
			end
			,AGE , PHONE, ADDRESS from INFO where ACCOUNT=@account
			return 
	END

CREATE proc doithongtin(@ACC VARCHAR(30),@NAME NVARCHAR(30),@SEX NVARCHAR(5),@AGE INT,@PHONE CHAR(10),@ADD NVARCHAR(30))
as
begin
	update INFO set NAME=@NAME,
		Sex=Case
		When @SEX='Nam' then 1
		else 0
		end,
		AGE=@AGE,
		PHONE=@PHONE,
		ADDRESS=@ADD
		WHERE ACCOUNT=@ACC
END
---hiển thị thực đơn
create function hienthiTD()
returns @bang table(
					NAME nvarchar(30),
					UNIT nvarchar(30),
					PRICE float,
					TYPE nvarchar(30)
					)
as
	begin
		insert into @bang 
		 select FOOD.NAME,UNIT,PRICE,FOODCATEGORY.NAME
								from FOOD inner join FOODCATEGORY on FOOD.TYPE=FOODCATEGORY.ID
				return
	end

	select * from hienthiTD()
--hiển thị thông tin
create function hienthiTDA(@Acc varchar(30))
returns @bang table(
					NAME nvarchar(30),
					SEX nvarchar(5),
					AGE int,
					PHONE nvarchar(30),
					ADDRESS nvarchar(30)
					)
as
	begin
		insert into @bang 
		 select NAME,
		 case
		 when SEX=0 then N'Nữ'
		 else N'Nam'
		 end
		 ,AGE,PHONE,ADDRESS
		from INFO 
		where ACCOUNT=@Acc
		return
	END
--Nhân viên
Alter function hienthiNV()
returns @bang table(
					ACCOUNT varchar(30),
					PASSWORD varchar(30),
					NAME nvarchar(30),
					SEX nvarchar(5),
					AGE int,
					PHONE nvarchar(30),
					ADDRESS nvarchar(30),
					TYPE nvarchar(20)
					)
as
	begin
		insert into @bang 
		 select ACCOUNT,PASSWORD,NAME,
			 case
			 when SEX=0 then N'Nữ'
			 else N'Nam'
			 end
		 ,AGE,PHONE,ADDRESS,
			 case
			 when TYPE=0 then N'Nhân viên'
			 else N'Quản lí'
			 end
		from INFO 
		return
	END
go
CREATE PROC DelFood(@IDT INT,@NameF NVARCHAR(30))
AS
BEGIN
	DECLARE @IDB INT
	DECLARE @IDF INT
	SELECT TOP 1 @IDB=ID FROM dbo.BILL WHERE TABLENUM=@IDT ORDER BY ID DESC
	SELECT @IDF=ID FROM dbo.FOOD WHERE NAME=@NameF
	DELETE dbo.BILLINFO WHERE IDBILL=@IDB AND IDFOOD=@IDF
END
EXEC dbo.DelFood @IDT = 8,  @NameF = N'Xoài dầm'


UPDATE dbo.TABLELIST SET STATUS=0
DELETE dbo.BILLINFO
DELETE dbo.BILL
DBCC CHECKIDENT (BILL,RESEED,0)
SELECT * FROM dbo.TABLELIST
SELECT * FROM dbo.BILL
SELECT * FROM dbo.BILLINFO
SELECT * FROM dbo.FOOD

EXEC dbo.ADDFOOD @IDT = 15, -- int
    @NAME = N'Pepsi', -- nvarchar(30)
    @AM = 5, -- int
    @ACC = 'admin1' -- varchar(30)

