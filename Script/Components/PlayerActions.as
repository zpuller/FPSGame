struct FValidActions {
    UPROPERTY()
    TArray<bool> ValidActions;
};

enum EPlayerAction {
    Sprint = 0,
    Crouch = 1,
    Slide = 2,
    Jump = 3,
    Vault = 4,
    Aim = 5,
    Fire = 6,
    Reload = 7,
    SwitchWeapons = 8,
};

class UPlayerActions : UActorComponent {
    TSet<EPlayerAction> ActiveActions;
    TArray<FName> RowNames;

    UPROPERTY()
    UDataTable ActionsDataTable;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        RowNames = ActionsDataTable.RowNames;
    }

    bool IsActionValid(EPlayerAction Action) const {
        FValidActions ValidActionsRow;
        if (!ActionsDataTable.FindRow(RowNames[Action], ValidActionsRow)) {
            Print(f"error: failed to look up ValidAction {}");
        }

        for (EPlayerAction ActiveAction : ActiveActions) {
            if (!ValidActionsRow.ValidActions[ActiveAction]) {
                return false;
            }
        }
        
        return true;
    }

    bool TryAction(EPlayerAction Action) {
        bool bIsActionValid = IsActionValid(Action);
        if (bIsActionValid) {
            ActiveActions.Add(Action);
        }
        return bIsActionValid;
    }

    UFUNCTION()
    bool IsActionActive(EPlayerAction Action) const {
        return ActiveActions.Contains(Action);
    }

    void StopAction(EPlayerAction action) {
        ActiveActions.Remove(action);
    }
}