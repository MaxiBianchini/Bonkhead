using UnityEngine;

public class BulletController : MonoBehaviour
{
    // Este m�todo se llama cuando un objeto con un colisionador 2D entra en contacto con el colisionador 2D adjunto a la bala.
    void OnTriggerEnter2D(Collider2D collision)
    {
        // Si el objeto que ha colisionado con la bala tiene la etiqueta "Player":
        if (collision.gameObject.CompareTag("Player"))
        {
            // Destruye la bala.
            Destroy(gameObject);
            // Llama al m�todo "TakeDamage()" del componente "CharacterController" adjunto al objeto que ha colisionado con la bala (el jugador).
            collision.GetComponent<CharacterController>().TakeDamage();
        }

        // Si el objeto que ha colisionado con la bala tiene la etiqueta "Ground":
        if (collision.gameObject.CompareTag("Ground"))
        {
            // Destruye la bala.
            Destroy(gameObject);
        }
    }

    // Este m�todo se llama cuando el objeto se vuelve invisible para la c�mara.
    void OnBecameInvisible()
    {
        // Destruye la bala.
        Destroy(gameObject);
    }
}
