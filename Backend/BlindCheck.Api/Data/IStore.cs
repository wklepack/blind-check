using BlindCheck.Api.Data.Entities;

namespace BlindCheck.Api.Data;

public interface IStore
{
    public Task<IEnumerable<BlindCheckForm>> GetAllBlindCheckFormsFromDbAsync();
    public Task<BlindCheckForm?> GetBlindCheckFromFromDbAsync(string contractNumber);
    public Task<BlindCheckForm> SaveBlindCheckFormAsync(BlindCheckForm form);
    public Task<int> SeedDatabaseFromEmbeddedFilesAsync();
    public Task<bool> UpdateBlindCheckVerificationAsync(string contractNumber, bool isVerified, string userName);
}