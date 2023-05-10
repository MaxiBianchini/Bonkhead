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

    // Start is called before the first frame update
    void Start()
    {
        
    }


    // Update is called once per frame
    void Update()
    {
        
    }
}
