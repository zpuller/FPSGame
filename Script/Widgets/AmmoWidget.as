class UAmmoWidgetScript : UUserWidget {
    FText Text;

    UFUNCTION()
    FText GetText() const {
        return Text;
    }

    void SetAmmo(int TextI) {
        Text = FText::AsNumber(TextI, FNumberFormattingOptions());
    }
}