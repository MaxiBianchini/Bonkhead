using UnityEngine;
using UnityEngine.SceneManagement;

public class EventCheck : MonoBehaviour
{

    public void StartButton()
    {
        SceneManager.LoadScene("Level_1");
    }

    public void CreditsButton()
    {
        SceneManager.LoadScene("Credits");
    }

    public void OptionsButton()
    {
        SceneManager.LoadScene("Options");
    }

    public void MenuButton()
    {
        SceneManager.LoadScene("Menu");
    }
}
