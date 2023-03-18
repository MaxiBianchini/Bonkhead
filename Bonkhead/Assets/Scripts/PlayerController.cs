using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerController : MonoBehaviour
{
public float Speed;
    public float MaxSpeed;

    public bool TocandoPiso;
   public bool TocandoPared;

    public float FuerzaSalto;
    private bool Saltar;
    public bool DobleSaltar;

    //private bool Slash;

    private bool movimiento;

    private SpriteRenderer spr;
    private Rigidbody2D rb2d;
   // private Animator anim;

   public GameObject Pies;

  //  private int Vida;

   // public Transform puntoinstancia;
   // public GameObject Bala;

   // private float tiempodisparo;

   // private GameObject level;

   // private GameObject Balas;
   // float Direccion;


    public Vector3 PosReinicio;

    // Start is called before the first frame update
    void Start()
    {
        movimiento = true;
        spr = GetComponent<SpriteRenderer>();
        rb2d = GetComponent<Rigidbody2D>();
       // anim = GetComponent<Animator>();

      //  level = GetCompon

        //Vida = 5;

        //Direccion = 1;
    }

    // Update is called once per frame

    void Update()
    {
     /*   anim.SetFloat("Speed", Mathf.Abs(rb2d.velocity.x));
        anim.SetBool("Grounded", TocandoPiso);*/

        //tiempodisparo += Time.deltaTime;

        if (Input.GetKeyDown(KeyCode.S) /*&& tiempodisparo >= 0.5f*/)
        {

            if (Input.GetKeyDown(KeyCode.UpArrow))
            {
                /* if (Input.GetKey(KeyCode.A))
                 {
                     Debug.Log("IZquierda");
                     Balas = Instantiate(Bala, puntoinstancia.position, Quaternion.identity);
                     Balas.GetComponent<Rigidbody2D>().velocity = new Vector2(-3f, 3f); ;
                 }
                 else if (Input.GetKey(KeyCode.D))
                 {
                     Debug.Log("derecha");
                     Balas = Instantiate(Bala, puntoinstancia.position, Quaternion.identity);
                     Balas.GetComponent<Rigidbody2D>().velocity = new Vector2(3f, 3f); ;
                 }
                 else
                }*/
              /*  Balas = Instantiate(Bala, puntoinstancia.position, Quaternion.identity);
                Balas.GetComponent<Rigidbody2D>().velocity = new Vector2(0f, 5 * MaxSpeed); ;*/
            }

        
        
        
            /*Balas = Instantiate(Bala, puntoinstancia.position, Quaternion.identity);
            Balas.GetComponent<Rigidbody2D>().velocity = new Vector2(Direccion * 5 * MaxSpeed, 0f);*/
        }



      

       /*     tiempodisparo = 0f;
        }*/

        if (Input.GetKeyDown(KeyCode.Space))
        {
            if (TocandoPiso || TocandoPared)
            {
                Saltar = true;
                DobleSaltar = true;

            }
            else if (DobleSaltar)
            {
                Saltar = true;
                DobleSaltar = false;
            }
        }
        /*if (Input.GetKeyDown(KeyCode.Tab))
        {
            Slash = true;
        }
*/
       /* if (Vida <= 0)
        {
            Destroy(gameObject);
            Application.LoadLevel(0);
        }*/
    }

    private void FixedUpdate()
    {
        ComprobarSuelo();

        Vector3 fixedVelocity = rb2d.velocity;
        fixedVelocity.x *= 0.75f;

        if (TocandoPiso)
        {
            rb2d.velocity = fixedVelocity;
        }

        float h = Input.GetAxis("Horizontal");
        if (!movimiento) h = 0;

        rb2d.AddForce(Vector2.right * Speed * h);

        float LimitSpeed = Mathf.Clamp(rb2d.velocity.x, -MaxSpeed, MaxSpeed);
        rb2d.velocity = new Vector2(LimitSpeed, rb2d.velocity.y);

        if (h > 0.1f)
        {
            transform.localScale = new Vector3(1f, 1f, 1f);
           /* Direccion = 1;*/
        }
        if (h < -0.1f)
        {
            transform.localScale = new Vector3(-1f, 1f, 1f);
            /*Direccion = -1;*/
        }

        if (Saltar)
        {
            rb2d.velocity = new Vector2(rb2d.velocity.x, 0);
            rb2d.AddForce(Vector2.up * FuerzaSalto, ForceMode2D.Impulse);
            Saltar = false;
        }

      /*  if (Slash)
        {
            // Personaje.velocity = new Vector2(Personaje.velocity.x, 0);
            rb2d.AddForce(Vector2.right * 80 * h, ForceMode2D.Impulse);
            Slash = false;
        }*/
    }
    void OnBecameInvisible()
    {
        //transform.position = PosReinicio;

        //si me caigo de la pantalla reinicio nivel

        Destroy(gameObject);
        /*Application.LoadLevel(1);*/

    }

    void OnTriggerEnter2D(Collider2D collision)
    {
      /*  if (collision.gameObject.tag == "BalaEnemigo")
        {
            // Destroy(gameObject);
            collision.SendMessage("EliminarBala");
            EnemyKnockBack(collision.transform.position.x);

           // Vida--;
        }

       /* if (collision.gameObject.tag == "Enemigo")
        {

            Debug.Log("contacto enemigo;");
            EnemyKnockBack(collision.transform.position.x);

            Vida--;
        }*/
    }

    private void OnCollisionStay2D(Collision2D collision)
    {
        if (collision.gameObject.tag == "Pared")
        {
            TocandoPared = true;
        }

         if(collision.transform.tag == "Platform")
            {
                TocandoPiso = true;
            }
    }

    private void OnCollisionExit2D(Collision2D collision)
    {
        if (collision.gameObject.tag == "Pared")
        {
            TocandoPared = false;
        }
    }



    void ComprobarSuelo()
    {
        /*RaycastHit2D colision = Physics2D.Raycast(new Vector2(Pies.transform.position.x, Pies.transform.position.y), new Vector2(0, -1), 0.05f);*/
      //  if(/*colision != null && colision.collider != null*/ ) {

            if(rb2d.transform.tag == "Platform")
            {
                TocandoPiso = true;
            }

           /* if (rb2d.transform.tag == "Plataforma Movil")
            {
                rb2d.velocity = new Vector3(0f, 0f, 0f);
                transform.parent = colision.transform;
                TocandoPiso = true;
            }*/

       // }
        else
        {
            TocandoPiso = false;
            transform.parent = null;
        }
    }

   /* public void EnemyJump()
    {
        Saltar = true;
    }

    public void EnemyKnockBack(float enemyPosX)
    {
        Saltar = true;

        float lado = Mathf.Sign(enemyPosX - transform.position.x);
        rb2d.AddForce(Vector2.left * lado * FuerzaSalto, ForceMode2D.Impulse);

        movimiento = false;
        Invoke("ActivarMovimiento", 0.7f);

        Color color = new Color(164 / 255f, 69 / 255f, 69 / 255f);
        spr.color = color;
    }

    void ActivarMovimiento()
    {
        movimiento = true;
        
        spr.color = Color.white;
    }*/
}
