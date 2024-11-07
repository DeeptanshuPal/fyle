//
//  CategoriesViewController.swift
//  fyle
//
//  Created by User@77 on 06/11/24.
//

import UIKit

class CategoriesViewController: GradientBGViewController {
    @IBOutlet weak var HomeCategoryView: UIView!
    @IBOutlet var VehicleCategoryView: UIView!
    @IBOutlet var SchoolCategoryView: UIView!
    @IBOutlet var BankCategoryView: UIView!
    @IBOutlet var MedicalCategoryView: UIView!
    @IBOutlet var CollegeCategoryView: UIView!
    @IBOutlet var WarrentyCategoryView: UIView!
    @IBOutlet var LandCategoryView: UIView!
    @IBOutlet var FamilyCategoryView: UIView!
    @IBOutlet var TravelCategoryView: UIView!
    @IBOutlet var BusinessCategoryView: UIView!
    @IBOutlet var InsuranceCategoryView: UIView!
    @IBOutlet var EducationCategoryView: UIView!
    @IBOutlet var MiscellaneousCategoryView: UIView!
    
    
    @IBOutlet weak var HomeCategoryImageView: UIView!
    @IBOutlet var VehicleCategoryImageView: UIView!
    @IBOutlet var SchoolCategoryImageView: UIView!
    @IBOutlet var BankCategoryImageView: UIView!
    @IBOutlet var MedicalCategoryImageView: UIView!
    @IBOutlet var CollegeCategoryImageView: UIView!
    @IBOutlet var WarrentyCategoryImageView: UIView!
    @IBOutlet var LandCategoryImageView: UIView!
    @IBOutlet var FamilyCategoryImageView: UIView!
    @IBOutlet var TravelCategoryImageView: UIView!
    @IBOutlet var BusinessCategoryImageView: UIView!
    @IBOutlet var InsuranceCategoryImageView: UIView!
    @IBOutlet var EducationCategoryImageView: UIView!
    @IBOutlet var MiscellaneousCategoryImageView: UIView!
    
    
    @IBOutlet weak var AddButtonView: UIView!
    
    // function to set corner radius for every category cell and image
    
    func setCornerRadius(CategoryView: UIView, CategoryImageView: UIView) {
        CategoryView.layer.cornerRadius = 11
        CategoryImageView.layer.cornerRadius = 47 / 2
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //List of all _CalegoryView Outlets
        let categoryViewOutlets: [UIView] = [HomeCategoryView, VehicleCategoryView, SchoolCategoryView, BankCategoryView,MedicalCategoryView,CollegeCategoryView, LandCategoryView, WarrentyCategoryView, FamilyCategoryView, TravelCategoryView, BusinessCategoryView, InsuranceCategoryView, EducationCategoryView, MiscellaneousCategoryView]
        
        //List of all _CalegoryImageView Outlets
        let categoryImageViewOutlets: [UIView] = [HomeCategoryImageView, VehicleCategoryImageView, SchoolCategoryImageView, BankCategoryImageView, MedicalCategoryImageView, CollegeCategoryImageView, LandCategoryImageView, WarrentyCategoryImageView, FamilyCategoryImageView, TravelCategoryImageView, BusinessCategoryImageView, InsuranceCategoryImageView, EducationCategoryImageView, MiscellaneousCategoryImageView]
        
        for (category, categoryImage) in zip(categoryViewOutlets, categoryImageViewOutlets) {
            setCornerRadius(CategoryView: category, CategoryImageView: categoryImage)
        }
        
        
        AddButtonView.layer.cornerRadius = 75/2
        AddButtonView.layer.shadowOffset = .zero
        AddButtonView.layer.shadowRadius = 10
    }

}
