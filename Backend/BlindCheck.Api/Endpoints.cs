using BlindCheck.Api.Data;
using BlindCheck.Api.Models;

namespace BlindCheck.Api;

public static class Endpoints
{
    public static void MapEndpoints(this WebApplication app)
    {
        app.MapGet("/api/blind-check-form", async (IStore store) =>
        {
            var entities = await store.GetAllBlindCheckFormsFromDbAsync();
            return Results.Ok(entities);
        })
        .WithName("GetAllBlindCheckForms");

        app.MapGet("/api/blind-check-form/{contractNumber}", async (string contractNumber, IStore store) =>
        {
            var entity = await store.GetBlindCheckFromFromDbAsync(contractNumber);
            if(entity == null)
            {
                return Results.NotFound(new
                {
                    message = $"Blind check form with case ID '{contractNumber}' not found."
                });
            }
            return Results.Ok(entity);
        })
        .WithName("GetBlindCheckForm");

        app.MapPost("/api/blind-check-form/{contractNumber}/verify", async (string contractNumber, VerifyBlindCheckRequest request, IStore store) =>
        {
            var entity = await store.GetBlindCheckFromFromDbAsync(contractNumber);
            if (entity == null)
            {
                return Results.NotFound(new
                {
                    message = $"Blind check form with contract number '{contractNumber}' not found."
                });
            }

            var updated = await store.UpdateBlindCheckVerificationAsync(contractNumber, request.IsVerified, request.UserName);
            if (!updated)
            {
                return Results.Problem("Failed to update blind check verification.");
            }

            return Results.Ok(new
            {
                message = "Blind check verification updated successfully.",
                contractNumber,
                isVerified = request.IsVerified
            });
        })
        .WithName("VerifyBlindCheck");
    }
}
