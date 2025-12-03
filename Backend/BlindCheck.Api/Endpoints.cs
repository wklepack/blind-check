using BlindCheck.Api.Data;

namespace BlindCheck.Api;

public static class Endpoints
{
    public static void MapEndpoints(this WebApplication app)
    {
        app.MapGet("/api/blind-check-form", async (IStore store) =>
        {
            var entities = await store.GetAllBlindCheckFormsAsync();
            return Results.Ok(entities);
        })
        .WithName("GetAllBlindCheckForms");

        app.MapGet("/api/blind-check-form/{caseId}", async (string caseId, IStore store) =>
        {
            var entity = await store.GetBlindCheckFormByCaseIdAsync(caseId);
            if(entity == null)
            {
                return Results.NotFound(new
                {
                    message = $"Blind check form with case ID '{caseId}' not found."
                });
            }
            return Results.Ok(entity);
        })
        .WithName("GetBlindCheckForm");
    }
}
