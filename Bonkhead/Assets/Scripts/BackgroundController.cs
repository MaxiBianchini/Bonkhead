using UnityEngine;

public class BackgroundController : MonoBehaviour
{
    [SerializeField] private Vector2 speedMovement;

    private Rigidbody2D rigidbodyPlayer;
    private Material material;

    private Vector2 offset;
    
    void Start()
    {
        material = GetComponent<SpriteRenderer>().material;
        rigidbodyPlayer = GameObject.FindGameObjectWithTag("Player").GetComponent<Rigidbody2D>();
    }

    void Update()
    {
        offset = (rigidbodyPlayer.velocity.x * 0.1f) * speedMovement * Time.deltaTime;
        material.mainTextureOffset += offset;
    }
}
