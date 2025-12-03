using BlindCheck.Api.Data.Entities;

namespace BlindCheck.Api.Data;

public interface IStore
{
    public Task<BlindCheckForm?> GetBlindCheckFormByCaseIdAsync(string caseId);
    public Task<BlindCheckForm?> GetBlindCheckFromFromDb(string caseId);
    public Task<BlindCheckForm> SaveBlindCheckFormAsync(BlindCheckForm form);
    public Task<int> SeedDatabaseFromEmbeddedFilesAsync();
    public Task<IEnumerable<BlindCheckForm>> GetAllBlindCheckFormsAsync();
    public Task<bool> UpdateBlindCheckVerificationAsync(string contractNumber, bool isVerified);
}