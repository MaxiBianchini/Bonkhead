using UnityEngine;

public class BulletController : MonoBehaviour
{
    public int damage = 10;

    void Start()
    {

    }

    void OnTriggerEnter2D(Collider2D collision)
    {
        if (collision.gameObject.tag == "Player")
        {
            Destroy(gameObject);
            collision.GetComponent<CharacterController>().TakeDamage();
        }

        if (collision.gameObject.tag == "Ground")
        {
            Destroy(gameObject);
        }
    }

    void OnBecameInvisible()
    {
        Destroy(gameObject);
    }
}
