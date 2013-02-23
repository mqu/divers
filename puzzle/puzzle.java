// auteur : Pierre Quinton - janvier 2013
// ébauche d'un solveur pour un puzzle 3x3
// - chaque pièce est constituée de 4 parties d'un corps (tete ou bas)
// - il y a 4 types d'insectes différents.
// - l'inventaire des pièces est réalisé dans le constructeur de Grid.
// - la résolution est basé sur un algorythme génétique (aléatoire).
//   mais est notoirement incomplet.

import java.util.*;

public class csaa
{
	private static Scanner sc = new Scanner(System.in);
	private Random r = new Random();
	public static void main(String[] args)
	{
		int N = 24; //nombre de population
		
		// Definition des different grid
		Grid[] g = new Grid[N];
		int[] tab = new int[9];		
		double[] resultat = new double[N];
		
		// remplissage aleatoire
		for(int j = 0 ; j < N ; ++j)
		{
			ran(tab);		
			for(int i = 0 ; i < 9 ; ++i)
			{	
				// Definition d'une direction aleatoire pour chaque element
				
				// assignement dans rotation de chaque element 
				g[j] = new Grid();
				g[j].set(i%3,i/3,tab[i],r.nextInt(3));
					
			}	
			resultat[j] = g[j].totalmatch();
			System.out.println(resultat[j]);
		}
		// Selection des k meilleurs
		int k = 6;
		int[] best = select(resultat, k);
		
		// generation d'une nouvelle population a partir des meilleurs resultat
		modificationtotal(N,best,g);

		//for(int i = 0 ; i < 9 ; ++i)
		//System.out.println(tab[i]);

	}
	public static void modificationtotal(int N, int[] best,Grid[] g)
	{
		
		for(int i = 0 ; i < best.lenght ; ++i)
		{
			for(int j = 0 ; j < N/best.lenght ; ++i)
			{
				g[i*N/best.lenght+j] = g[best[i]].modificationAleatoire();				
			}
		}
	}
	public static int[] select(double[] tab, int n)
	{
		int[] res = new int[n];
		double[] dRes = new double[n];
		for(int i = 0 ; i < n ; ++i)
		{
			dRes[i] = 0.0;
			res[i] = 0;
		}
		for(int i = 0 ; i < tab.length ; ++i)
		{
			for(int j = 0 ; j < n ; ++j)
			{
				if(dRes[j] < tab[i])
				{
					dRes[j] = tab[i];
					res[j] = i;
					break;
				}
			}
		}
		return res;
	}
	 
	public static void ran(int[] prec)
	{
				
		for(int i = 0 ; i < 9 ; ++i)
			prec[i] = i;
		
		for (int i = 0; i < 9; i++) {
			int position = i + r.nextInt(9 - i);
			int temp = prec[i];
			prec[i] = prec[position];
			prec[position] = temp;
		}
		
	}
}

class Grid
{
	static private Random r = new Random();
	private Case[] m_elements;
	private int[][] m_grid;
	public Grid() /* 
					   0 cocc
					   1 cocc cul
					   2 sauterelle
					   3 sauterelle cul
					   4 ar
					   5 ar cul
					   6 ab
					   7 ab cul 
					*/
	{
		m_elements = new Case[9];
			m_elements[0] = new Case(4, 0, 1, 2);
			m_elements[1] = new Case(7, 2, 0, 5);
			m_elements[2] = new Case(3, 5, 7, 1);
			m_elements[3] = new Case(6, 4, 0, 3);
			m_elements[4] = new Case(6, 4, 3, 5);
			m_elements[5] = new Case(5, 0, 2, 6);
			m_elements[6] = new Case(6, 3, 1, 4);
			m_elements[7] = new Case(6, 7, 3, 0);
			m_elements[8] = new Case(6, 4, 1, 3);
			
		m_grid = new int[3][3];

		for(int i = 0 ; i < 3 ; ++i)
		{
			for(int j = 0 ; j < 3 ; ++j)
			{
				m_grid[i][j] = j*3+i;
			}
		}
	}
	public Grid modificationAleatoire();
	{
		Grid gridmodifie = new Grid();
		gridmodifie.m_grid = m_grid;
		
		
		int proba = r.nextInt(19);
		//probalite de switch horisontal 5%
		if(proba == 0)
		{
			a=r.nextInt(2);
			b=r.nextInt(2);
			int temp_1,temp_2,temp_3;
			temp_1 = gridmodifie.m_grid[a][1];
			temp_2 = gridmodifie.m_grid[a][2];
			temp_3 = gridmodifie.m_grid[a][3];
			
			gridmodifie.m_grid[a][1] = gridmodifie.m_grid[b][1];
			gridmodifie.m_grid[a][2] = gridmodifie.m_grid[b][2];
			gridmodifie.m_grid[a][3] = gridmodifie.m_grid[b][3];
			
			gridmodifie.m_grid[b][1]= temp_1;
			gridmodifie.m_grid[b][2]= temp_2;
			gridmodifie.m_grid[b][3]= temp_3;
			
		}
		proba = r.nextInt(19);
		//probalite de switch horisontal 5%
		if(proba == 0) 
		{
			a=r.nextInt(2);
			b=r.nextInt(2);
			int temp_1,temp_2,temp_3;
			temp_1 = gridmodifie.m_grid[1][a];
			temp_2 = gridmodifie.m_grid[2][a];
			temp_3 = gridmodifie.m_grid[3][a];
			
			gridmodifie.m_grid[1][a] = gridmodifie.m_grid[1][b];
			gridmodifie.m_grid[2][a] = gridmodifie.m_grid[2][b];
			gridmodifie.m_grid[3][a] = gridmodifie.m_grid[3][b];
			
			gridmodifie.m_grid[1][b]= temp_1;
			gridmodifie.m_grid[2][b]= temp_2;
			gridmodifie.m_grid[3][b]= temp_3;
			
		}
		// a ajouter : les rotations
		
	}
	public void set(int x, int y, int numero, int dir)
	{
		m_elements[numero].setDir(dir);
		m_grid[x][y] = numero;
	}
	
	public static boolean match(int a, int b) // 0 coc, 1 cul cocc, etc ...
	{
		return (a / 2 == b / 2 && a % 2 != b % 2);
	}
	
	public double totalmatch() 
	{
		double res = 0;
		for(int i = 0 ; i < 3 ; ++i)
		{
			if(match(m_elements[m_grid[0][i]].get(2), m_elements[m_grid[1][i]].get(0)))
				res++;
			if(match(m_elements[m_grid[1][i]].get(2), m_elements[m_grid[2][i]].get(0)))
				res++;
			if(match(m_elements[m_grid[i][0]].get(3), m_elements[m_grid[i][1]].get(1)))
				res++;
			if(match(m_elements[m_grid[i][1]].get(3), m_elements[m_grid[i][2]].get(1)))
				res++;
		}
		return res;
	}
	
	public void draw()
	{
		for(int i = 0 ; i  < 3 ; ++i)
		{
			for(int j = 0 ; j < 3 ; ++j)
			{
				System.out.print("\t" + m_elements[m_grid[j][i]].get(1)/2 + ((m_elements[m_grid[j][i]].get(1) % 2 == 0) ? "" : "'") + "\t");
			}
			System.out.println();
			for(int j = 0 ; j < 3 ; ++j)
			{
				System.out.print(m_elements[m_grid[j][i]].get(0)/2 + ((m_elements[m_grid[j][i]].get(0) % 2 == 0) ? "" : "'") + "\t\t" + m_elements[m_grid[j][i]].get(2)/2 + ((m_elements[m_grid[j][i]].get(2) % 2 == 0) ? "" : "'"));
			}
			System.out.println();
			for(int j = 0 ; j < 3 ; ++j)
			{
				System.out.print("\t" + m_elements[m_grid[j][i]].get(3)/2 + ((m_elements[m_grid[j][i]].get(3) % 2 == 0) ? "" : "'") + "\t");
			}
			System.out.println();
		}
	}
}

class Case
{
	private int [] m_elements;
	public Case(int a, int b, int c, int d)
	{
		m_elements = new int[4];
		m_elements[0] = a;
		m_elements[1] = b;
		m_elements[2] = c;
		m_elements[3] = d;
	}
	
		
	public int get(int index)	{
		return m_elements[index];
	}
	
	public void setDir(int dir)
	{
		int[] temp = m_elements.clone();
		for(int i = 0 ; i < 4; ++i)
		{
			m_elements[i] = temp[(i + dir) % 4];
		}
	}
}

