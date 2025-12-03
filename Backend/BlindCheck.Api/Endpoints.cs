using BlindCheck.Api.Data;
using BlindCheck.Api.Mappers;

namespace BlindCheck.Api;

public static class Endpoints
{
    public static void MapEndpoints(this WebApplication app)
    {
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
            var viewModel = BlindCheckFormMapper.ToViewModel(entity);
            return Results.Ok(viewModel);
        })
        .WithName("GetBlindCheckForm");
    }
}
