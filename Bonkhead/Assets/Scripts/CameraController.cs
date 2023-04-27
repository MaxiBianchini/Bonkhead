using UnityEngine;

public class CameraController : MonoBehaviour
{
    public GameObject target; // Objeto de juego al que seguir con la cámara

    public float rightMax; // Límite máximo hacia la derecha
    public float leftMax; // Límite máximo hacia la izquierda
    public float downMax; // Límite máximo hacia abajo
    public float upMax; // Límite máximo hacia arriba

    // Esta función se llama una vez por cuadro y se utiliza para actualizar la posición de la cámara
    void Update()
    {
        // Vector3 que representa la posición deseada de la cámara
        Vector3 desiredPosition = new Vector3(
            Mathf.Clamp(target.transform.position.x, leftMax, rightMax), // La posición en X de la cámara se establece en la posición actual del objeto de destino, pero se limita dentro de los valores mínimos y máximos establecidos
            Mathf.Clamp(target.transform.position.y, downMax, upMax), // La posición en Y de la cámara se establece en la posición actual del objeto de destino, pero se limita dentro de los valores mínimos y máximos establecidos
            transform.position.z // La posición en Z de la cámara no cambia
        );

        // Se establece la posición de la cámara en la posición deseada
        transform.position = desiredPosition;
    }
}
