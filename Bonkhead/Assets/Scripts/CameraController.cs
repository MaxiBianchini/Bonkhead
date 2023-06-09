using UnityEngine;

public class CameraController : MonoBehaviour
{
    public GameObject target; // Objeto de juego al que seguir con la c�mara

    public float rightMax; // L�mite m�ximo hacia la derecha
    public float leftMax; // L�mite m�ximo hacia la izquierda
    public float downMax; // L�mite m�ximo hacia abajo
    public float upMax; // L�mite m�ximo hacia arriba

    // Esta funci�n se llama una vez por cuadro y se utiliza para actualizar la posici�n de la c�mara
    void Update()
    {
        // Vector3 que representa la posici�n deseada de la c�mara
        Vector3 desiredPosition = new Vector3(
            Mathf.Clamp(target.transform.position.x, leftMax, rightMax), // La posici�n en X de la c�mara se establece en la posici�n actual del objeto de destino, pero se limita dentro de los valores m�nimos y m�ximos establecidos
            Mathf.Clamp(target.transform.position.y, downMax, upMax), // La posici�n en Y de la c�mara se establece en la posici�n actual del objeto de destino, pero se limita dentro de los valores m�nimos y m�ximos establecidos
            transform.position.z // La posici�n en Z de la c�mara no cambia
        );

        // Se establece la posici�n de la c�mara en la posici�n deseada
        transform.position = desiredPosition;
    }
}
