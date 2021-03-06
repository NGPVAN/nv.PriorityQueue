��IF (NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'jobs')) 

BEGIN

    EXEC ('CREATE SCHEMA [jobs] AUTHORIZATION [dbo]')

END



IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jobs].[Type]') AND type in (N'U'))

BEGIN

	CREATE TABLE [jobs].[Type](

		[Id] [smallint] IDENTITY(1,1) NOT NULL,

		[Name] [varchar](256) NOT NULL,

	 CONSTRAINT [PK_Type] PRIMARY KEY CLUSTERED 

	(

		[Id] ASC

	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

	) ON [PRIMARY]

END



IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jobs].[PriorityQueue]') AND type in (N'U'))

BEGIN

	CREATE TABLE [jobs].[PriorityQueue](

		[Id] [bigint] IDENTITY(1,1) NOT NULL,

		[TenantId] [smallint] NOT NULL CONSTRAINT [DF__Queue__TenantId]  DEFAULT (-1),

		[PrincipalId] [smallint] NOT NULL CONSTRAINT [DF__Queue__PrincipalId]  DEFAULT (-1),

		[TypeId] [smallint] NOT NULL,

		[Priority] [tinyint] NOT NULL CONSTRAINT [DF__Queue__Priority]  DEFAULT (128),

		[IsInProgress] [bit] NULL CONSTRAINT [DF__Queue__IsInProgress]  DEFAULT (NULL),

		[Payload] [varchar](max) NOT NULL,

		[CreatedOn] [datetime] NOT NULL CONSTRAINT [DF__Queue__CreatedOn]  DEFAULT (getutcdate()),

		[ModifiedOn] [datetime] NOT NULL CONSTRAINT [DF__Queue__ModifiedOn]  DEFAULT (getutcdate()),

		CONSTRAINT [PK_Queue] PRIMARY KEY CLUSTERED (

			[Id] ASC

		) ON [PRIMARY]

	) ON [PRIMARY]



	CREATE NONCLUSTERED INDEX [IX_IsInProgress] ON [jobs].[PriorityQueue] 

	(

		[IsInProgress] ASC

	)

	INCLUDE ( 

		[Id],

		[Priority]) 

	WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

END

GO



IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jobs].[Priority]') AND type in (N'U'))

BEGIN

	CREATE TABLE [jobs].[Priority](

		[TypeId] smallint NOT NULL,

		[TenantId] smallint NOT NULL CONSTRAINT [DF__Priority__TenantId]  DEFAULT (-1),

		[Priority] tinyint NOT NULL CONSTRAINT [DF__Priority__Priority]  DEFAULT (128),

	) ON [PRIMARY]

END

GO



IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jobs].[usp_Enqueue]') AND type in (N'P'))

DROP PROCEDURE [jobs].[usp_Enqueue]

GO



CREATE PROCEDURE [jobs].[usp_Enqueue] 

		@Payload VARCHAR(MAX),

		@Type VARCHAR(256),

		@TenantId SMALLINT = -1,

		@PrincipalId SMALLINT = -1,

		@Priority TINYINT = null

	AS

BEGIN

	DECLARE @TypeId SMALLINT



	SELECT @TypeId=Id FROM [jobs].[Type] (nolock) where [Name] = @Type



	IF(@TypeId IS NULL)

	BEGIN

		INSERT INTO [jobs].[Type] (Name)

		VALUES (@Type)



		SET @TypeId = @@IDENTITY



		INSERT INTO [jobs].[Priority] ([TypeId])

		VALUES (@TypeId)

	END



	IF(@Priority IS NULL)

	BEGIN					

		SELECT TOP 1 

			@Priority = [Priority]

		FROM 

			[jobs].[Priority] p				

		WHERE 

			p.TypeId = @TypeId AND TenantId IN (@TenantId, -1)

		ORDER BY TenantId DESC

	END



	INSERT INTO jobs.[PriorityQueue]

			( TenantId,

				PrincipalId,

				TypeId,

				Payload,

				[Priority])		

	VALUES(

		@TenantId,

		@PrincipalId,

		@TypeId,

		@Payload,

		@Priority)



	RETURN 0

END

GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jobs].[usp_Dequeue]') AND type in (N'P'))

DROP PROCEDURE [jobs].[usp_Dequeue]

GO



CREATE PROCEDURE [jobs].[usp_Dequeue]

AS

BEGIN



		UPDATE [PriorityQueue] WITH (UPDLOCK, READPAST)

			SET 

					[IsInProgress] = 1,

					[ModifiedOn] = GETUTCDATE()

		OUTPUT 

			[INSERTED].[Id] ,

			[INSERTED].[TenantId],

			[INSERTED].[PrincipalId],

			[INSERTED].[Payload],

			[INSERTED].[Priority],

			t.Name as [Type],

			[INSERTED].IsInProgress,

			[INSERTED].CreatedOn,

			[INSERTED].ModifiedOn

		FROM PriorityQueue q

		LEFT JOIN [Type] t ON t.Id = q.TypeId

		WHERE (q.[Id] IN (SELECT TOP 1 [Id]

							FROM [jobs].[PriorityQueue] WITH (UPDLOCK, READPAST) 

							WHERE [IsInProgress] IS NULL AND [Priority] > 0

							ORDER BY [Priority] DESC, [Id] ASC))

END

GO



IF NOT EXISTS (SELECT * 

           FROM sys.foreign_keys 

           WHERE object_id = OBJECT_ID(N'[jobs].[FK_PriorityQueue_Type]') 

             AND parent_object_id = OBJECT_ID(N'[jobs].[PriorityQueue]'))

BEGIN			

	ALTER TABLE [jobs].[PriorityQueue]  

		WITH CHECK ADD CONSTRAINT [FK_PriorityQueue_Type] FOREIGN KEY([TypeId])

		REFERENCES [jobs].[Type] ([Id])

		ON UPDATE CASCADE

		ON DELETE CASCADE



	ALTER TABLE [jobs].[PriorityQueue] 

	CHECK CONSTRAINT [FK_PriorityQueue_Type]

END

GO



IF NOT EXISTS (SELECT * 

           FROM sys.foreign_keys 

           WHERE object_id = OBJECT_ID(N'[jobs].[FK_Priority_Type]') 

             AND parent_object_id = OBJECT_ID(N'[jobs].[Priority]'))

BEGIN

	ALTER TABLE [jobs].[Priority]  

		WITH CHECK ADD  CONSTRAINT [FK_Priority_Type] FOREIGN KEY([TypeId])

	REFERENCES [jobs].[Type] ([Id])



	ALTER TABLE [jobs].[Priority] CHECK CONSTRAINT [FK_Priority_Type]

END

GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[jobs].[vwSummary]') AND [type] = 'V')

DROP VIEW jobs.vwSummary

GO



CREATE VIEW jobs.vwSummary AS

SELECT     

	COUNT(1) AS [Count], 

	jobs.PriorityQueue.TenantId, 

	jobs.PriorityQueue.PrincipalId, 

	jobs.[Priority].[Priority], 

	jobs.Type.Name,

	jobs.PriorityQueue.IsInProgress

FROM         

	jobs.PriorityQueue WITH (NOLOCK) 

	INNER JOIN jobs.Type (NOLOCK) ON jobs.PriorityQueue.TypeId = jobs.Type.Id 

	INNER JOIN jobs.Priority (NOLOCK) ON jobs.Type.Id = jobs.Priority.TypeId

GROUP BY 

	jobs.Priority.Priority, 

	jobs.Type.Name, 

	jobs.PriorityQueue.TenantId, 

	jobs.PriorityQueue.PrincipalId,

	jobs.PriorityQueue.IsInProgress

GO
