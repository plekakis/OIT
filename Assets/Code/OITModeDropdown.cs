using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class OITModeDropdown : MonoBehaviour {

    public OITCamera m_camera;
    private Dropdown m_dropdown;

    private void Awake()
    {
        m_dropdown = GetComponent<Dropdown>();
        //Add listener for when the value of the Dropdown changes, to take action
        m_dropdown.onValueChanged.AddListener(
        delegate 
        {
            OnValueChanged(m_dropdown);
        });
    }
    
	public void OnValueChanged(Dropdown value)
    {
        m_camera.m_sortMode = (SortMode)value.value;
    }
}
